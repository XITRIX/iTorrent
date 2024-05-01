//
//  RssFeedProvider.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 07.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import Combine
import Foundation
import MvvmFoundation
import SWXMLHash

extension RssFeedProvider {
    enum RssError: LocalizedError {
        case unknown
        case wrongUrl
        case feedExists

        var errorDescription: String? {
            switch self {
            case .unknown: return "RssFeedProvider.Error.Unknown"
            case .wrongUrl: return "RssFeedProvider.Error.NotValid"
            case .feedExists: return "RssFeedProvider.Error.Exists"
            }
        }
    }
}

@MainActor
class RssFeedProvider {
    @Published var rssModels: [RssModel]
    let updatePublisher = CurrentValueSubject<Void, Never>(())

    convenience init() {
        self.init(fetchUpdatesOnInit: true)
        updatePublisher.send()
    }

    init(fetchUpdatesOnInit: Bool) {
        rssModels = Self.loadFromDisk()
        disposalBag.bind {
            $rssModels.sink(receiveValue: Self.saveToDisk)
        }
        if fetchUpdatesOnInit {
            Task { try await fetchUpdates() }
        }
    }

    func saveState() {
        Self.saveToDisk(rssModels)
        updatePublisher.send()
    }

    private let disposalBag = DisposeBag()
}

extension RssFeedProvider {
    @discardableResult
    func fetchUpdates() async throws -> [RssModel: [RssItemModel]] {
        var res: [RssModel: [RssItemModel]] = [:]
        for feed in rssModels {
            if Task.isCancelled { break }
            res[feed] = try await feed.update()
        }
        Self.saveToDisk(rssModels)
        return res
    }

    func addFeed(_ url: String) async throws -> RssModel {
        guard let url = URL(string: url) else {
            throw RssError.wrongUrl
        }

        if rssModels.contains(where: { $0.xmlLink == url }) {
            throw RssError.feedExists
        }

        let model = try await RssModel(link: url)
        await MainActor.run {
            rssModels.insert(model, at: 0)
        }
        return model
    }

    func removeFeeds(_ feedModels: [RssModel]) {
        for url in feedModels {
            if let index = rssModels.firstIndex(of: url) {
                rssModels.remove(at: index)
            }
        }
    }

    var hasNewsPublisher: AnyPublisher<Bool, Never> {
        updatePublisher
            .map { [unowned self] in rssModels.flatMap { $0.items }.contains(where: { $0.new }) }
        .eraseToAnyPublisher()
    }
}

private extension RssFeedProvider {
    static func saveToDisk(_ models: [RssModel]) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(models) {
            let defaults = UserDefaults.standard
            defaults.set(encoded, forKey: "RssFeed")
        }
    }

    static func loadFromDisk() -> [RssModel] {
        let defaults = UserDefaults.standard
        guard let rssFeed = defaults.object(forKey: "RssFeed") as? Data,
              let loadedRssFeed = try? JSONDecoder().decode([RssModel].self, from: rssFeed)
        else { return [] }

        return loadedRssFeed
    }
}
