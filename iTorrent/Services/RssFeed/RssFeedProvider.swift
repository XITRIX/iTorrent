//
//  RssFeedProvider.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 07.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import Foundation
import SWXMLHash

extension RssFeedProvider {
    enum RssError: LocalizedError {
        case unknown
        case wrongUrl
        case feedExists
        case feedNotFound
        case corruptedData

        var errorDescription: String? {
            switch self {
            case .unknown: return "RssFeedProvider.Error.Unknown"
            case .wrongUrl: return "RssFeedProvider.Error.NotValid"
            case .feedExists: return "RssFeedProvider.Error.Exists"
            case .feedNotFound: return "RssFeedProvider.Error.NotFound"
            case .corruptedData: return "RssFeedProvider.Error.CorruptedData"
            }
        }
    }
}

actor RssFeedProvider {
    init() {
        self.init(fetchUpdatesOnInit: true)
    }

    init(fetchUpdatesOnInit: Bool) {
        rssModels = Self.loadFromDisk()
        searchIndex = Self.makeSearchIndex(from: rssModels)

        if fetchUpdatesOnInit {
            Task { [weak self] in
                try? await self?.fetchUpdates()
            }
        }
    }

    private var rssModels: [RssFeedSnapshot]
    private var searchIndex: [RssSearchIndexEntry] = []
    private var continuations: [UUID: AsyncStream<[RssFeedSnapshot]>.Continuation] = [:]
}

extension RssFeedProvider {
    func feeds() -> [RssFeedSnapshot] {
        rssModels
    }

    func feed(id: URL) -> RssFeedSnapshot? {
        rssModels.first { $0.id == id }
    }

    func allItems() -> [RssSearchResultSnapshot] {
        rssModels.flatMap { feed in
            feed.items.map { RssSearchResultSnapshot(feedID: feed.id, item: $0) }
        }
    }

    func updates() -> AsyncStream<[RssFeedSnapshot]> {
        AsyncStream { continuation in
            let id = UUID()
            continuation.yield(rssModels)
            continuations[id] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { await self?.removeContinuation(id) }
            }
        }
    }

    func hasNews() -> Bool {
        rssModels.flatMap(\.items).contains { $0.new }
    }

    func searchItems(query: String) -> [RssSearchResultSnapshot] {
        let query = RssSearchQuery(query)
        guard !query.tokens.isEmpty else { return [] }

        return searchIndex
            .filter { entry in
                query.tokens.allSatisfy { entry.normalizedTitle.contains($0) } ||
                    query.tokens.allSatisfy { entry.normalizedDescription.contains($0) }
            }
            .sorted { $0.item.date ?? .distantPast > $1.item.date ?? .distantPast }
            .map { .init(feedID: $0.feedID, item: $0.item) }
    }

    @discardableResult
    func fetchUpdates() async throws -> [RssFeedSnapshot: [RssItemSnapshot]] {
        var result: [RssFeedSnapshot: [RssItemSnapshot]] = [:]

        for feed in rssModels {
            try Task.checkCancellation()
            let fetched = try await RssFeedClient.fetch(feed.xmlLink)
            guard let index = rssModels.firstIndex(where: { $0.id == feed.id }) else { continue }
            let newItems = merge(fetched, into: index)
            result[rssModels[index]] = newItems
        }

        persistAndNotify()
        return result
    }

    @discardableResult
    func refreshFeed(id: URL) async throws -> [RssItemSnapshot] {
        guard let index = rssModels.firstIndex(where: { $0.id == id }) else {
            throw RssError.feedNotFound
        }

        let fetched = try await RssFeedClient.fetch(rssModels[index].xmlLink)
        let newItems = merge(fetched, into: index)
        persistAndNotify()
        return newItems
    }

    @discardableResult
    func addFeed(_ urlString: String) async throws -> RssFeedSnapshot {
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw RssError.wrongUrl
        }

        guard !rssModels.contains(where: { $0.xmlLink == url }) else {
            throw RssError.feedExists
        }

        let fetched = try await RssFeedClient.fetch(url)
        rssModels.insert(fetched, at: 0)
        persistAndNotify()
        return fetched
    }

    func removeFeeds(ids: [URL]) {
        rssModels.removeAll { ids.contains($0.id) }
        persistAndNotify()
    }

    func reorderFeeds(ids: [URL]) {
        let byID = Dictionary(uniqueKeysWithValues: rssModels.map { ($0.id, $0) })
        var reordered = ids.compactMap { byID[$0] }
        let known = Set(ids)
        reordered.append(contentsOf: rssModels.filter { !known.contains($0.id) })
        rssModels = reordered
        persistAndNotify()
    }

    func markItemRead(feedID: URL, itemID: String, read: Bool) {
        guard let feedIndex = rssModels.firstIndex(where: { $0.id == feedID }),
              let itemIndex = rssModels[feedIndex].items.firstIndex(where: { $0.id == itemID })
        else { return }

        rssModels[feedIndex].items[itemIndex].readed = read
        rssModels[feedIndex].items[itemIndex].new = false
        persistAndNotify()
    }

    func markMatchingItemRead(_ item: RssItemSnapshot, read: Bool) {
        for feedIndex in rssModels.indices {
            guard let itemIndex = rssModels[feedIndex].items.firstIndex(of: item) else { continue }
            rssModels[feedIndex].items[itemIndex].readed = read
            rssModels[feedIndex].items[itemIndex].new = false
            persistAndNotify()
            return
        }
    }

    func markFeedRead(id: URL) {
        guard let feedIndex = rssModels.firstIndex(where: { $0.id == id }) else { return }
        for itemIndex in rssModels[feedIndex].items.indices {
            rssModels[feedIndex].items[itemIndex].new = false
        }
        persistAndNotify()
    }

    func updatePreferences(id: URL, customTitle: String?, customDescription: String?, muteNotifications: Bool?) {
        guard let index = rssModels.firstIndex(where: { $0.id == id }) else { return }
        if let customTitle { rssModels[index].customTitle = customTitle }
        if let customDescription { rssModels[index].customDescription = customDescription }
        if let muteNotifications { rssModels[index].muteNotifications = muteNotifications }
        persistAndNotify()
    }

    func exportChannelURLs(indexes: [IndexPath]) -> [URL] {
        rssModels.enumerated()
            .filter { indexes.isEmpty || indexes.contains(IndexPath(item: $0.offset, section: 0)) }
            .map { $0.element.xmlLink }
    }
}

private extension RssFeedProvider {
    func merge(_ fetched: RssFeedSnapshot, into index: Int) -> [RssItemSnapshot] {
        var feed = rssModels[index]
        feed.title = fetched.title
        feed.description = fetched.description
        feed.link = fetched.link
        feed.linkImage = fetched.linkImage

        var oldItems = feed.items
        var newItems = fetched.items.filter { item in
            if let oldIndex = oldItems.firstIndex(of: item) {
                let readed = oldItems[oldIndex].readed
                let new = oldItems[oldIndex].new
                oldItems[oldIndex].update(item)
                oldItems[oldIndex].readed = readed
                oldItems[oldIndex].new = new
                return false
            }
            return true
        }

        newItems.mutableForEach { $0.new = true }
        feed.items = newItems + oldItems
        rssModels[index] = feed
        return newItems
    }

    func persistAndNotify() {
        rebuildSearchIndex()
        Self.saveToDisk(rssModels)
        continuations.values.forEach { $0.yield(rssModels) }
    }

    func rebuildSearchIndex() {
        searchIndex = Self.makeSearchIndex(from: rssModels)
    }

    static func makeSearchIndex(from feeds: [RssFeedSnapshot]) -> [RssSearchIndexEntry] {
        feeds.flatMap { feed in
            feed.items.map { item in
                RssSearchIndexEntry(feedID: feed.id, item: item)
            }
        }
    }

    func removeContinuation(_ id: UUID) {
        continuations[id] = nil
    }

    static func saveToDisk(_ models: [RssFeedSnapshot]) {
        guard let encoded = try? JSONEncoder().encode(models) else { return }
        UserDefaults.standard.set(encoded, forKey: storageKey)
    }

    static func loadFromDisk() -> [RssFeedSnapshot] {
        guard let rssFeed = UserDefaults.standard.object(forKey: storageKey) as? Data,
              let loadedRssFeed = try? JSONDecoder().decode([RssFeedSnapshot].self, from: rssFeed)
        else { return [] }

        return loadedRssFeed
    }

    static var storageKey: String { "RssFeed" }
}

private struct RssSearchIndexEntry: Sendable {
    let feedID: URL
    let item: RssItemSnapshot
    let normalizedTitle: String
    let normalizedDescription: String

    init(feedID: URL, item: RssItemSnapshot) {
        self.feedID = feedID
        self.item = item
        normalizedTitle = RssItemSnapshot.normalize(item.title ?? "")
        normalizedDescription = RssItemSnapshot.normalize(item.description ?? "")
    }
}

private enum RssFeedClient {
    static func fetch(_ url: URL) async throws -> RssFeedSnapshot {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let contents = String(data: data, encoding: .utf8) else {
            throw RssFeedProvider.RssError.corruptedData
        }

        let xml = XMLHash.parse(contents)
        let title = xml["rss"]["channel"]["title"].element?.text ?? "RSS Feed"
        let description = xml["rss"]["channel"]["description"].element?.text
        let linkText = xml["rss"]["channel"]["link"].element?.text
        let link = URL(string: linkText)
        let linkImage = URL(string: "https://www.google.com/s2/favicons?sz=128&domain_url=" + (linkText ?? url.absoluteString))
        let items = xml["rss"]["channel"]["item"].all.map(RssItemSnapshot.init(xml:))

        return RssFeedSnapshot(
            xmlLink: url,
            title: title,
            description: description,
            linkImage: linkImage,
            link: link,
            items: items
        )
    }
}
