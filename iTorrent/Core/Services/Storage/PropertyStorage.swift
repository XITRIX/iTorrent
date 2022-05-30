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

    @StoredProperty(id: "backgroundProcessing") var backgroundProcessing = true
    @StoredProperty(id: "allowBackgroundSeeding") var allowBackgroundSeeding = false

    @StoredProperty(id: "maxActiveTorrents") var maxActiveTorrents = 5
    @StoredProperty(id: "maxDownloadingTorrents") var maxDownloadingTorrents = 3
    @StoredProperty(id: "maxUploadingTorrents") var maxUploadingTorrents = 3

    @StoredProperty(id: "maxDownloadSpeed") var maxDownloadSpeed: UInt = 0
    @StoredProperty(id: "maxUploadSpeed") var maxUploadSpeed: UInt = 0
}
