//
//  PreferencesStorage.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 07/11/2023.
//

import Foundation

class PreferencesStorage {
    private init() {}
    static let shared = PreferencesStorage()

    @UserDefaultItem("torrentListSortType", .alphabetically) var torrentListSortType: TorrentListViewModel.Sort
    @UserDefaultItem("torrentListSortReverced", false) var torrentListSortReverced: Bool
}
