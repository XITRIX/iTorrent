//
//  Settings+LocalStorage.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 14.05.2022.
//

import Foundation
import TorrentKit
import MVVMFoundation

extension Session.Settings {
    static func fromPropertyStorage() -> Session.Settings {
        let propStorage = MVVM.resolve() as PropertyStorage

        let storage = Session.Settings()
        storage.preallocateStorage = propStorage.preallocationStorage
        storage.maxActiveTorrents = propStorage.maxActiveTorrents
        storage.maxDownloadingTorrents = propStorage.maxDownloadingTorrents
        storage.maxUploadingTorrents = propStorage.maxUploadingTorrents
        return storage
    }
}
