//
//  RssModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 06.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import Foundation
import SWXMLHash

typealias RssModel = RssFeedSnapshot
typealias RssItemModel = RssItemSnapshot

struct RssFeedSnapshot: Hashable, Codable, Identifiable, Sendable {
    var id: URL { xmlLink }

    let xmlLink: URL
    var title: String
    var description: String?
    var linkImage: URL?
    var link: URL?
    var items: [RssItemSnapshot]
    var customTitle: String?
    var customDescription: String?
    var muteNotifications: Bool

    var displayTitle: String {
        if let customTitle, !customTitle.isEmpty { return customTitle }
        return title
    }

    var displayDescription: String {
        if let customDescription, !customDescription.isEmpty { return customDescription }
        return description ?? ""
    }

    var updatesCount: Int {
        items.filter(\.new).count
    }

    init(
        xmlLink: URL,
        title: String,
        description: String? = nil,
        linkImage: URL? = nil,
        link: URL? = nil,
        items: [RssItemSnapshot] = [],
        customTitle: String? = nil,
        customDescription: String? = nil,
        muteNotifications: Bool = false
    ) {
        self.xmlLink = xmlLink
        self.title = title
        self.description = description
        self.linkImage = linkImage
        self.link = link
        self.items = items
        self.customTitle = customTitle
        self.customDescription = customDescription
        self.muteNotifications = muteNotifications
    }
}

extension RssItemSnapshot {
    struct Enclosure: Hashable, Codable, Sendable {
        var url: URL
        var type: String
        var length: Int
    }
}

struct RssItemSnapshot: Hashable, Codable, Identifiable, Sendable {
    var title: String?
    var description: String?
    var guid: String?
    var date: Date?
    var link: URL?
    var enclosure: Enclosure?

    var new: Bool = false
    var readed: Bool = false

    var id: String {
        if let guid, !guid.isEmpty { return "guid:\(guid)" }
        return [title, description, date?.timeIntervalSince1970.description, link?.absoluteString]
            .compactMap { $0 }
            .joined(separator: "|")
    }

    init(
        title: String? = nil,
        description: String? = nil,
        guid: String? = nil,
        date: Date? = nil,
        link: URL? = nil,
        enclosure: Enclosure? = nil,
        new: Bool = false,
        readed: Bool = false
    ) {
        self.title = title
        self.description = description
        self.guid = guid
        self.date = date
        self.link = link
        self.enclosure = enclosure
        self.new = new
        self.readed = readed
    }

    init(xml: XMLIndexer) {
        title = xml["title"].element?.text
        description = xml["description"].element?.text
        link = URL(string: xml["link"].element?.text)
        guid = xml["guid"].element?.text

        if let dateText = xml["pubDate"].element?.text {
            date = Self.dateFormatter.date(from: dateText)
        }

        if let enclosure = xml["enclosure"].element,
           let url = URL(string: enclosure.attribute(by: "url")?.text),
           let type = enclosure.attribute(by: "type")?.text,
           let length = Int(enclosure.attribute(by: "length")?.text ?? "0")
        {
            self.enclosure = .init(url: url, type: type, length: length)
        }
    }

    mutating func update(_ model: RssItemSnapshot) {
        title = model.title
        description = model.description
        date = model.date
        link = model.link
        enclosure = model.enclosure
    }

    func matches(_ query: RssSearchQuery) -> Bool {
        guard !query.tokens.isEmpty else { return true }
        let normalizedTitle = Self.normalize(title ?? "")
        let normalizedDescription = Self.normalize(description ?? "")
        return query.tokens.allSatisfy { normalizedTitle.contains($0) } ||
            query.tokens.allSatisfy { normalizedDescription.contains($0) }
    }

    static func == (lhs: RssItemSnapshot, rhs: RssItemSnapshot) -> Bool {
        if let lg = lhs.guid, let rg = rhs.guid {
            return lg == rg
        }
        return lhs.title == rhs.title &&
            lhs.description == rhs.description &&
            lhs.date == rhs.date &&
            lhs.link == rhs.link
    }

    func hash(into hasher: inout Hasher) {
        if let guid {
            hasher.combine(guid)
            return
        }

        hasher.combine(title)
        hasher.combine(description)
        hasher.combine(date)
        hasher.combine(link)
    }
}

struct RssSearchResultSnapshot: Hashable, Identifiable, Sendable {
    var id: String { "\(feedID.absoluteString)|\(item.id)" }

    let feedID: URL
    let item: RssItemSnapshot
}

struct RssSearchQuery: Sendable {
    let tokens: [String]

    init(_ text: String) {
        tokens = RssItemSnapshot.normalize(text)
            .split(separator: " ")
            .map(String.init)
    }
}

extension RssItemSnapshot {
    static func normalize(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
        return formatter
    }()
}

extension URL {
    init?(string: String?) {
        guard let string else { return nil }
        self.init(string: string)
    }
}
