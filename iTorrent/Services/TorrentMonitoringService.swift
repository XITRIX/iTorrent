//
//  TorrentMonitoringService.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 03/04/2024.
//

import LibTorrent
import MvvmFoundation
import UIKit
import UserNotifications

class TorrentMonitoringService {
    private let disposeBag = DisposeBag()
    @Injected private var torrentService: TorrentService

    init() {
        disposeBag.bind {
            torrentService.updateNotifier.sink { [unowned self] updateModel in
                checkDoneNotification(with: updateModel)
                checkStorageAvailability(with: updateModel)
            }
        }
    }
}

private extension TorrentMonitoringService {
    func checkStorageAvailability(with model: TorrentService.TorrentUpdateModel) {
        guard let handle = model.handle,
              let snapshot = handle.currentSnapshot,
              let storage = handle.storage,
              !storage.allowed,
              !snapshot.isPaused
        else { return }

        Task { await handle.pause() }
    }

    func checkDoneNotification(with model: TorrentService.TorrentUpdateModel) {
        let oldSnapshot = model.oldSnapshot

        guard let handle = model.handle,
              let snapshot = handle.currentSnapshot,
              PreferencesStorage.shared.isDownloadNotificationsEnabled,
              oldSnapshot.state != .checkingFiles,
              oldSnapshot.friendlyState != .paused,
              oldSnapshot.progressWanted < 1,
              snapshot.progressWanted >= 1
        else { return }

        if PreferencesStorage.shared.stopSeedingOnFinish {
            Task { await handle.pause() }
        }

        let content = UNMutableNotificationContent()

        let hash = snapshot.infoHashes.best.hex
        content.title = %"notification.done.title"
        content.body = %"notification.done.message_\(snapshot.name)"
        content.sound = UNNotificationSound.default
        content.userInfo = ["hash": hash]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let identifier = hash
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber += 1
        }
    }
}
