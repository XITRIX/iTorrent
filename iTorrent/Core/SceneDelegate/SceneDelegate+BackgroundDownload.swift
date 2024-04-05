//
//  SceneDelegate+BackgroundDownload.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 05.04.2024.
//

import Combine
import LibTorrent

extension SceneDelegate {
    func startBackgroundIfNeeded() {
        if PreferencesStorage.shared.isBackgroundDownloadEnabled, Self.isBackgroundNeeded {
            BackgroundService.shared.start()
        }
    }

    func stopBackground() {
        BackgroundService.shared.stop()
    }

    var backgroundStateObserverBind: AnyCancellable {
        TorrentService.shared.updateNotifier
            .filter { _ in BackgroundService.shared.isRunning }
            .filter { $0.oldSnapshot.friendlyState != $0.handle.snapshot.friendlyState }
            .sink { _ in
                guard !Self.isBackgroundNeeded else { return }
                BackgroundService.shared.stop()
            }
    }
}

private extension SceneDelegate {
    static var isBackgroundNeeded: Bool {
        TorrentService.shared.torrents.contains(where: { $0.needBackground })
    }
}

private extension TorrentHandle.Snapshot {
    var needBackground: Bool {
        false
            || friendlyState == .checkingFiles
            || friendlyState == .checkingResumeData
            || friendlyState == .downloading
            || friendlyState == .downloadingMetadata
            || (friendlyState == .seeding && PreferencesStorage.shared.isBackgroundSeedingEnabled)
    }
}
