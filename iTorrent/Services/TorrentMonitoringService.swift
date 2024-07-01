//
//  TorrentMonitoringService.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 03/04/2024.
//

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
        guard let storage = model.handle.storage,
              !storage.allowed,
              !model.handle.snapshot.isPaused
        else { return }

        model.handle.pause()
    }

    func checkDoneNotification(with model: TorrentService.TorrentUpdateModel) {
        guard PreferencesStorage.shared.isDownloadNotificationsEnabled,
              model.oldSnapshot.state != .checkingFiles,
              model.oldSnapshot.progressWanted < 1,
              model.handle.snapshot.progressWanted >= 1
        else { return }

        if PreferencesStorage.shared.stopSeedingOnFinish {
            model.handle.pause()
        }

        let content = UNMutableNotificationContent()

        let hash = model.handle.snapshot.infoHashes.best.hex
        content.title = %"notification.done.title"
        content.body = %"notification.done.message_\(model.handle.snapshot.name)"
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
