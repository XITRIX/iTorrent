//
//  Core+TorrentStates.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 30.03.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

extension Core {
    @objc func managerStateChanged(notfication: NSNotification) {
        if let userInfo = notfication.userInfo?["data"] as? (manager: TorrentModel, oldState: TorrentState, newState: TorrentState) {
            managersStateChanged(manager: userInfo.manager, oldState: userInfo.oldState, newState: userInfo.newState)
        }
    }
    
    func managersStateChanged(manager: TorrentModel, oldState: TorrentState, newState: TorrentState) {
        if oldState == .metadata {
            save_magnet_to_file(manager.hash)
        }
        if UserPreferences.notificationsKey.value &&
            (oldState == .downloading && (newState == .finished || newState == .seeding)) {
            NotificationHelper.showNotification(title: Localize.get("Download finished"),
                                                body: manager.title + Localize.get(" finished downloading"),
                                                hash: manager.hash)

            if UserPreferences.badgeKey.value && AppDelegate.backgrounded {
                UIApplication.shared.applicationIconBadgeNumber += 1
            }

            BackgroundTask.checkToStopBackground()
        }
        if UserPreferences.notificationsSeedKey.value &&
            (oldState == .seeding && (newState == .finished)) {
            NotificationHelper.showNotification(title: Localize.get("Seeding finished"),
                                                body: manager.title + Localize.get(" finished seeding"),
                                                hash: manager.hash)

            if UserPreferences.badgeKey.value && AppDelegate.backgrounded {
                UIApplication.shared.applicationIconBadgeNumber += 1
            }

            BackgroundTask.checkToStopBackground()
        }
    }
}
