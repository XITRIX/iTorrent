//
//  TorrentMonitoringService.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 03/04/2024.
//

import MvvmFoundation
import UserNotifications

class TorrentMonitoringService {
    private let disposeBag = DisposeBag()
    @Injected private var torrentService: TorrentService

    init() {
        disposeBag.bind {
            torrentService.updateNotifier.sink { [unowned self] updateModel in
                checkDoneNotification(with: updateModel)
            }
        }
    }
}

private extension TorrentMonitoringService {
    func checkDoneNotification(with model: TorrentService.TorrentUpdateModel) {
        guard PreferencesStorage.shared.isDownloadNotificationsEnabled,
              model.oldSnapshot.state != .checkingFiles,
              model.oldSnapshot.progressWanted < 1,
              model.handle.snapshot.progressWanted >= 1
        else { return }

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
    }
}
