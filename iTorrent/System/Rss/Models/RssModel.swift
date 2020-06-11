//
//  RssModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 06.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import DeepDiff
import Foundation
import SwiftyXMLParser

class RssModel: Hashable, Codable, DiffAware {
    var xmlLink: URL
    var title: String
    var description: String
    var linkImage: URL
    var link: URL
    var items: [RssItemModel] = []
    
    //
    var customTitle: String?
    var customDescriotion: String?
    var muteNotifications: Bool = false
    
    //
    var displayTitle: String {
        if customTitle?.isEmpty == false {
            return customTitle!
        }
        return title
    }
    var displayDescription: String {
        if customDescriotion?.isEmpty == false {
            return customDescriotion!
        }
        return description
    }
    var updatesCount: Int {
        items.filter { $0.new }.count
    }
    
    init(link: URL) throws {
        xmlLink = link
        
        do {
            let contents = try String(contentsOf: xmlLink)
            let xml = try XML.parse(contents)
            
            title = xml["rss", "channel", "title"].text!
            description = xml["rss", "channel", "description"].text!
            self.link = URL(string: xml["rss", "channel", "link"].text!)!
            linkImage = URL(string: "https://www.google.com/s2/favicons?domain=" + xml["rss", "channel", "link"].text!)!
            
            for xmlItem in xml["rss", "channel", "item"] {
                items.append(RssItemModel(xml: xmlItem))
            }
        } catch {
            throw error
        }
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
            lhs.customTitle == rhs.customTitle &&
            lhs.description == rhs.description &&
            lhs.customDescriotion == rhs.customDescriotion &&
            lhs.muteNotifications == rhs.muteNotifications &&
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
        hasher.combine(guid)
    }
    
    static func == (lhs: RssItemModel, rhs: RssItemModel) -> Bool {
        lhs.guid == rhs.guid
    }
    
    mutating func update(_ model: RssItemModel) {
        title = model.title
        description = model.description
        date = model.date
        link = model.link
    }
}
