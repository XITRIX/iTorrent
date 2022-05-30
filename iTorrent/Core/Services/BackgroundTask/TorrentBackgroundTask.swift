//
//  TorrentBackgroundTask.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 29.05.2022.
//

import Foundation
import MVVMFoundation
import TorrentKit

class TorrentBackgroundTask {
    let backgroundTask = BackgroundTask()
    let preferences = MVVM.resolve() as PropertyStorage
    let torrentManager = MVVM.resolve() as TorrentManager

    @discardableResult
    func startBackground() -> Bool {
        if preferences.backgroundProcessing {
            if torrentManager.torrents.values.contains(where: { (status) -> Bool in
                getBackgroundConditions(status)
            }) {
                backgroundTask.startBackgroundTask()
                return true
            }
        }
        return false
    }

    func stop() {
        backgroundTask.stopBackgroundTask()
    }

    func checkToStopBackground() {
        if backgroundTask.backgrounding {
            if !torrentManager.torrents.values.contains(where: { getBackgroundConditions($0) }) {
//                Core.shared.saveTorrents()
                backgroundTask.stopBackgroundTask()
            }
        }
    }

    func getBackgroundConditions(_ status: TorrentHandle) -> Bool {
        // state conditions
        (status.displayState == .downloading ||
            status.displayState == .downloadingMetadata ||
            status.displayState == .checkingFiles ||
            (status.displayState == .seeding &&
             preferences.allowBackgroundSeeding &&
                status.allowSeeding)
        )
//         ||
//            (UserPreferences.ftpKey &&
//                UserPreferences.ftpBackgroundKey)) &&
//            // zero speed limit conditions
//            ((UserPreferences.zeroSpeedLimit > 0 &&
//                    Core.shared.torrentsUserData[status.hash]?.zeroSpeedTimeCounter ?? 0 < UserPreferences.zeroSpeedLimit) ||
//                UserPreferences.zeroSpeedLimit == 0)
    }
}
