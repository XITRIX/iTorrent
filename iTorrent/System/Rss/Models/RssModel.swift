//
//  RssModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 06.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import Bond
import DeepDiff
import Foundation
import ReactiveKit
import SwiftyXMLParser

class RssModel: Hashable, Codable, DiffAware {
    enum Error: Swift.Error {
        case missingKey
    }
    
    var xmlLink: URL
    var title: String
    var description: String?
    var linkImage: URL?
    var link: URL?
    var items: [RssItemModel] = []
    
    //
    var customTitle = Observable<String?>(nil)
    var customDescriotion = Observable<String?>(nil)
    var muteNotifications = Observable<Bool>(false)
    //
    
//    private enum CodingKeys: String, CodingKey {
//        case xmlLink, title, description, linkImage, link, items, customTitle, customDescriotion, muteNotifications
//    }
//
//    required init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        xmlLink = try container.decode(URL.self, forKey: .xmlLink)
//        title = try container.decode(String.self, forKey: .title)
//        description = try container.decode(String.self, forKey: .description)
//        linkImage = try container.decode(URL.self, forKey: .linkImage)
//        link = try container.decode(URL.self, forKey: .link)
//        items = try container.decode([RssItemModel].self, forKey: .items)
//        customTitle.value = try container.decode(String?.self, forKey: .customTitle)
//        customDescriotion.value = try container.decode(String?.self, forKey: .customDescriotion)
//        muteNotifications.value = try container.decode(Bool.self, forKey: .muteNotifications)
//    }
//
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(xmlLink, forKey: .xmlLink)
//        try container.encode(title, forKey: .title)
//        try container.encode(description, forKey: .description)
//        try container.encode(linkImage, forKey: .linkImage)
//        try container.encode(link, forKey: .link)
//        try container.encode(items, forKey: .items)
//        try container.encode(customTitle.value, forKey: .customTitle)
//        try container.encode(customDescriotion.value, forKey: .customDescriotion)
//        try container.encode(muteNotifications.value, forKey: .muteNotifications)
//    }
    
    var updatesCount: Int {
        items.filter { $0.new }.count
    }
    
    init(link: URL) throws {
        xmlLink = link
        
        do {
            let contents = try String(contentsOf: xmlLink)
            let xml = try XML.parse(contents)
            
            let title = xml["rss", "channel", "title"].text
            let description = xml["rss", "channel", "description"].text
            
            self.title = title ?? "RSS Feed".localized
            self.description = description
            
            if let xmlLink = xml["rss", "channel", "link"].text,
               let link = URL(string: xmlLink),
               let linkImage = URL(string: "https://www.google.com/s2/favicons?domain=" + xmlLink) {
                self.link = link
                self.linkImage = linkImage
            }
            
            for xmlItem in xml["rss", "channel", "item"] {
                items.append(RssItemModel(xml: xmlItem))
            }
        } catch {
            throw error
        }
    }
    
    var displayTitle: String {
        if let title = customTitle.value,
            !title.isEmpty { return title }
        return title
    }
    
    var displayDescription: String? {
        if let description = customDescriotion.value,
            !description.isEmpty { return description }
        return description
    }

    @discardableResult func update(_ model: RssModel) -> [RssItemModel] {
        title = model.title
        description = model.description
        linkImage = model.linkImage
        link = model.link
        
        var new = model.items.filter { !items.contains($0) }
        for i in 0 ..< new.count {
            new[i].new = true
        }
        items.insert(contentsOf: new, at: 0)
        
        let updates = model.items.filter { items.contains($0) }
        for i in 0 ..< updates.count {
            let index = items.firstIndex(of: updates[i])!
            items[index].update(updates[i])
        }
        
        items.removeDuplicates()
        
        return new
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(xmlLink)
    }
    
    static func == (lhs: RssModel, rhs: RssModel) -> Bool {
        lhs.xmlLink == rhs.xmlLink &&
            lhs.title == rhs.title &&
            lhs.description == rhs.description &&
            lhs.customTitle.value == rhs.customTitle.value &&
            lhs.customDescriotion.value == rhs.customDescriotion.value &&
            lhs.muteNotifications.value == rhs.muteNotifications.value &&
            lhs.linkImage == rhs.linkImage &&
            lhs.items == rhs.items
    }
}

struct RssItemModel: Hashable, Codable, DiffAware {
    var title: String?
    var description: String?
    var guid: String?
    var date: Date?
    var link: URL
    
    var new: Bool = false
    var readed: Bool = false
    
    init(xml: XML.Accessor) {
        title = xml["title"].text
        description = xml["description"].text
        link = URL(string: xml["link"].text!)!
        guid = xml["guid"].text
        
        // Sun, 10 Feb 2019 17:23:50 +0400
        if let dateText = xml["pubDate"].text {
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
           let rg = rhs.guid {
            return lg == rg
        }
        return lhs.title == rhs.title &&
            lhs.description == rhs.description &&
            lhs.date == rhs.date &&
            lhs.link == rhs.link
    }
    
    mutating func update(_ model: RssItemModel) {
        title = model.title
        description = model.description
        date = model.date
        link = model.link
    }
}
