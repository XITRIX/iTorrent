//
//  PropertyStorage.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 27.04.2022.
//

import Bond
import Foundation
import ReactiveKit

class PropertyStorage {
    // Torrents list
    @StoredProperty(id: "torrentListSortingType") var torrentListSortingType = TorrentListSortingModel(type: .name)

    // Properties
    @StoredProperty(id: "preallocationStorage") var preallocationStorage = false
    @StoredProperty(id: "maxActiveTorrents") var maxActiveTorrents = 5
    @StoredProperty(id: "maxActiveTorrents") var maxDownloadingTorrents = 3
    @StoredProperty(id: "maxActiveTorrents") var maxUplodingTorrents = 3
}
