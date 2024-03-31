//
//  PreferencesStorage.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 07/11/2023.
//

import Combine
import Foundation
import LibTorrent
import MvvmFoundation

class PreferencesStorage {
    private init() {}
    private var disposeBag: [AnyCancellable] = []

    static let shared = PreferencesStorage()

    @UserDefaultItem("torrentListSortType", .alphabetically) var torrentListSortType: TorrentListViewModel.Sort
    @UserDefaultItem("torrentListSortReverced", false) var torrentListSortReverced: Bool

    @UserDefaultItem("preferencesAllocateMemory", false) var allocateMemory: Bool

    @UserDefaultItem("preferencesMaxActiveTorrents", 4) var maxActiveTorrents: Int
    @UserDefaultItem("preferencesMaxDownloadingTorrents", 3) var maxDownloadingTorrents: Int
    @UserDefaultItem("preferencesMaxUploadingTorrents", 3) var maxUploadingTorrents: Int

    @UserDefaultItem("preferencesMaxUploadSpeed", 0) var maxUploadSpeed: UInt
    @UserDefaultItem("preferencesMaxDownloadSpeed", 0) var maxDownloadSpeed: UInt

    var settingsUpdatePublisher: AnyPublisher<Void, Never> {
        Just<Void>(())
            .combineLatest($allocateMemory)
            .combineLatest($maxActiveTorrents)
            .combineLatest($maxDownloadingTorrents)
            .combineLatest($maxUploadingTorrents)
            .combineLatest($maxUploadSpeed)
            .combineLatest($maxDownloadSpeed)
            .map { _ in }
            .eraseToAnyPublisher()
    }
}

extension Session.Settings {
    static func fromPreferences() -> Self {
        let settings = Self()
        let preferences = PreferencesStorage.shared
        settings.maxActiveTorrents = preferences.maxActiveTorrents
        settings.maxDownloadingTorrents = preferences.maxDownloadingTorrents
        settings.maxUploadingTorrents = preferences.maxUploadingTorrents
        settings.maxUploadSpeed = preferences.maxUploadSpeed
        settings.maxDownloadSpeed = preferences.maxDownloadSpeed
        return settings
    }
}
