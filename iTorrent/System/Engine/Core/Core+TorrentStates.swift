//
//  Core+TorrentStates.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 30.03.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

#if TRANSMISSION
import ITorrentTransmissionFramework
#else
import ITorrentFramework
#endif

import UIKit

extension Core {
    func managersStateUpdate(manager: TorrentModel, oldState: TorrentState) {
        let newState = manager.displayState
        
        if oldState == newState { return }
        
        if oldState == .metadata {
            TorrentSdk.saveMagnetToFile(hash: manager.hash)
            return
        }
        
        if UserPreferences.notificationsKey &&
            (oldState == .downloading && (newState == .finished || newState == .seeding)) {
            NotificationHelper.showNotification(title: Localize.get("Download finished"),
                                                body: manager.title + Localize.get(" finished downloading"),
                                                hash: manager.hash)

            if UserPreferences.badgeKey && AppDelegate.backgrounded {
                UIApplication.shared.applicationIconBadgeNumber += 1
            }
            
            return
        }
        
        if UserPreferences.notificationsSeedKey &&
            (oldState == .seeding && (newState == .finished)) {
            NotificationHelper.showNotification(title: Localize.get("Seeding finished"),
                                                body: manager.title + Localize.get(" finished seeding"),
                                                hash: manager.hash)

            if UserPreferences.badgeKey && AppDelegate.backgrounded {
                UIApplication.shared.applicationIconBadgeNumber += 1
            }
            
            return
        }
        
        BackgroundTask.shared.checkToStopBackground()
    }
}
