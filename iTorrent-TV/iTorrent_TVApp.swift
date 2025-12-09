//
//  iTorrent_TVApp.swift
//  iTorrent-TV
//
//  Created by Daniil Vinogradov on 09/12/2025.
//

import SwiftUI
import MvvmFoundation

@main
struct iTorrent_TVApp: App {
    init() {
        let container = Mvvm.shared.container
        container.registerSingleton(factory: { TorrentService.shared })
        container.registerSingleton(factory: { PreferencesStorage.shared })
        container.registerSingleton(factory: NetworkMonitoringService.init)
        container.registerSingleton(factory: TrackersListService.init)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .environmentObject(TorrentService.shared)
    }
}
