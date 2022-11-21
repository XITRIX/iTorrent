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
import iTorrent_ProgressWidgetExtension
import ActivityKit

extension Core {
    func managersStateUpdate(manager: TorrentModel, oldState: TorrentState) {
        updateLiveActivity(with: manager, oldState: oldState)
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

private extension Core {
    func updateLiveActivity(with manager: TorrentModel, oldState: TorrentState) {
        if oldState != manager.state,
           manager.displayState == .downloading {
            showLiveActivity(with: manager)
        } else {
            update(with: manager)
        }
    }

    func getState(from manager: TorrentModel) -> iTorrent_ProgressWidgetAttributes.ContentState {
        .init(progress: Double(manager.progress),
              speed: manager.downloadRate,
              timeRemainig: Utils.downloadingTimeRemainText(speedInBytes: Int64(manager.downloadRate), fileSize:manager.totalWanted, downloadedSize: manager.totalWantedDone),
              timeStamp: Date())
    }

    func showLiveActivity(with manager: TorrentModel) {
        if #available(iOS 16.1, *) {
            let attributes = iTorrent_ProgressWidgetAttributes(name: manager.title)
            let contentState = getState(from: manager)

            do {
                _ = try Activity<iTorrent_ProgressWidgetAttributes>.request(attributes: attributes, contentState: contentState, pushType: .none)
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    func update(with manager: TorrentModel) {
        if #available(iOS 16.1, *) {
            Task {
                for activity in Activity<iTorrent_ProgressWidgetAttributes>.activities {
                    if activity.attributes.name == manager.title {
                        if manager.displayState == .downloading {
                            let contentState = getState(from: manager)
                            await activity.update(using: contentState, alertConfiguration: .none)
                        } else {
                            await activity.end(dismissalPolicy: .immediate)
                        }
                    }
                }
            }
        }
    }
}
