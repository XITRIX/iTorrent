//
//  RssModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 06.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import Combine
import Foundation
import MvvmFoundation
import SWXMLHash

class RssModel: Hashable, Codable {
    enum Error: Swift.Error {
        case missingKey
        case corruptedData
    }

    var xmlLink: URL
    @Published var title: String
    @Published var description: String?
    @Published var linkImage: URL?
    @Published var link: URL?
    @Published var items: [RssItemModel] = []

    //
    @Published var customTitle: String? = nil
    @Published var customDescriotion: String? = nil
    @Published var muteNotifications: Bool = false
    //

    var updatesCount: AnyPublisher<Int, Never> {
        $items.map { $0.filter { $0.new }.count }.eraseToAnyPublisher()
    }

    init(link: URL) async throws {
        xmlLink = link

        let (data, _) = try await URLSession.shared.data(from: xmlLink)
        guard let contents = String(data: data, encoding: .utf8)
        else { throw Error.corruptedData }

        let xml = XMLHash.parse(contents)

        let title = xml["rss"]["channel"]["title"].element?.text
        let description = xml["rss"]["channel"]["description"].element?.text

        self.title = title ?? "RSS Feed"
        self.description = description

        if let xmlLink = xml["rss"]["channel"]["link"].element?.text,
           let link = URL(string: xmlLink),
           let linkImage = URL(string: "https://www.google.com/s2/favicons?domain=" + xmlLink)
        {
            self.link = link
            self.linkImage = linkImage
        }

        for xmlItem in xml["rss"]["channel"]["item"].all {
            items.append(RssItemModel(xml: xmlItem))
        }
    }

    var displayTitle: String {
        if let title = customTitle,
           !title.isEmpty { return title }
        return title
    }

    var displayDescription: String? {
        if let description = customDescriotion,
           !description.isEmpty { return description }
        return description
    }

    func update() async throws {
        let (data, _) = try await URLSession.shared.data(from: xmlLink)
        guard let contents = String(data: data, encoding: .utf8)
        else { throw Error.corruptedData }

        let xml = XMLHash.parse(contents)

        let title = xml["rss"]["channel"]["title"].element?.text
        let description = xml["rss"]["channel"]["description"].element?.text

        var localLink: URL?
        var localLinkImage: URL?
        if let xmlLink = xml["rss"]["channel"]["link"].element?.text,
           let link = URL(string: xmlLink),
           let linkImage = URL(string: "https://www.google.com/s2/favicons?domain=" + xmlLink)
        {
            localLink = link
            localLinkImage = linkImage
        }

        var newItems = xml["rss"]["channel"]["item"].all.map { xmlItem in
            RssItemModel(xml: xmlItem)
        }.filter { !items.contains($0) }

        newItems.mutableForEach { $0.new = true }

        await MainActor.run { [newItems, localLink, localLinkImage] in
            self.title = title ?? "RSS Feed"
            self.description = description
            self.link = localLink
            self.linkImage = localLinkImage
            items = newItems + items
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(xmlLink)
    }

    static func == (lhs: RssModel, rhs: RssModel) -> Bool {
        lhs.xmlLink == rhs.xmlLink &&
            lhs.title == rhs.title &&
            lhs.description == rhs.description &&
            lhs.customTitle == rhs.customTitle &&
            lhs.customDescriotion == rhs.customDescriotion &&
            lhs.muteNotifications == rhs.muteNotifications &&
            lhs.linkImage == rhs.linkImage &&
            lhs.items == rhs.items
    }
}

struct RssItemModel: Hashable, Codable {
    var title: String?
    var description: String?
    var guid: String?
    var date: Date?
    var link: URL

    var new: Bool = false
    var readed: Bool = false

    init(xml: XMLIndexer) {
        title = xml["title"].element?.text
        description = xml["description"].element?.text
        link = URL(string: xml["link"].element!.text)!
        guid = xml["guid"].element?.text

        // Sun, 10 Feb 2019 17:23:50 +0400
        if let dateText = xml["pubDate"].element?.text {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
            date = formatter.date(from: dateText)
        }
    }

    func hash(into hasher: inout Hasher) {
        if let guid = guid {
            hasher.combine(guid)
            return
        }

        hasher.combine(title)
        hasher.combine(description)
        hasher.combine(date)
        hasher.combine(link)
    }

    static func == (lhs: RssItemModel, rhs: RssItemModel) -> Bool {
        if let lg = lhs.guid,
           let rg = rhs.guid
        {
            return lg == rg
        }
        return lhs.title == rhs.title &&
            lhs.description == rhs.description &&
            lhs.date == rhs.date &&
            lhs.link == rhs.link &&
            lhs.new == rhs.new &&
            lhs.readed == rhs.readed
    }

    mutating func update(_ model: RssItemModel) {
        title = model.title
        description = model.description
        date = model.date
        link = model.link
    }
}
