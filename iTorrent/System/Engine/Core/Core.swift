//
//  Core.swift
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

import Foundation
import GCDWebServer
import ReactiveKit
import Bond

class Core: NSObject {
    private(set) static var shared: Core!
    
    public static func configure() {
        if shared != nil { return }
        shared = Core()
    }
    
    var state = Observable<CoreState>(.Initializing)
    
    var torrents: [String: TorrentModel] = [:]
    var torrentsUserData: [String: UserManagerSettings] = [:]
    
    let webUploadServer = GCDWebUploader(uploadDirectory: Core.rootFolder)
    let webDAVServer = GCDWebDAVServer(uploadDirectory: Core.rootFolder)
    
    private override init() {
        super.init()
        
        TorrentSdk.initEngine(downloadFolder: Core.rootFolder, configFolder: Core.configFolder, settingsPack: SettingsPack.userPrefered)
        
        DispatchQueue.global(qos: .background).async {
            self.restoreAllTorrents()
            
            let allocateStorage = UserPreferences.storagePreallocation
            TorrentSdk.setStoragePreallocation(allocate: allocateStorage)
            
            FileManager.default.clearTmpDirectory()
            
            self.state.value = .InProgress

            while true {
                self.mainLoop()
                sleep(1)
            }
        }
    }
    
    func mainLoop() {
        /// update torrents states
        let res = TorrentSdk.getTorrents()

        for torrent in res {
            var torrent = torrent

            if let t = torrents[torrent.hash] {
                let oldState = t.displayState
                t.update(with: torrent)
                torrent = t
                managersStateUpdate(torrent, oldState: oldState)
            } else {
                torrents[torrent.hash] = torrent
            }
            
            updateSavedData(model: torrent)
            torrent.stateCorrector()
        }
        
        /// call engine's alerts loop method
        TorrentSdk.popAlerts()
        
        /// remove removed torrents
        let removed = torrents.values.filter {!res.contains($0)}
        for file in removed {
            removedManager(file)
            torrents[file.hash] = nil
        }

        /// check torrents speed to stop if == 0
        for torrent in torrents.values {
            checkSpeed(model: torrent)
        }

        /// notify to update UI
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .mainLoopTick, object: nil)
        }
    }
    
    private func updateSavedData(model: TorrentModel) {
        if Core.shared.torrentsUserData[model.hash] == nil {
            Core.shared.torrentsUserData[model.hash] = UserManagerSettings()
        }
        
        guard let userData = Core.shared.torrentsUserData[model.hash] else { return }
        
        model.addedDate = userData.addedDate
        model.seedMode = userData.seedMode
        model.seedLimit = userData.seedLimit

        userData.totalDownloadSession = model.totalDownloadSession
        userData.totalUploadSession = model.totalUploadSession

        model.totalDownload = userData.totalDownload
        model.totalUpload = userData.totalUpload
    }
    
    private func checkSpeed(model: TorrentModel) {
        guard let userData = Core.shared.torrentsUserData[model.hash] else {
            return
        }

        if model.displayState == .downloading,
            model.downloadRate <= 25000,
            BackgroundTask.shared.backgrounding {
            userData.zeroSpeedTimeCounter += 1
        } else {
            userData.zeroSpeedTimeCounter = 0
        }

        if userData.zeroSpeedTimeCounter == UserPreferences.zeroSpeedLimit,
            UserPreferences.zeroSpeedLimit != 0 {
            NotificationHelper.showNotification(
                title: Localize.get("BackgroundTask.LowSpeed.Title") + "(\(Utils.getSizeText(size: Int64(model.downloadRate)))/s)",
                body: model.title + Localize.get("BackgroundTask.LowSpeed.Message"),
                hash: model.hash)
            BackgroundTask.shared.checkToStopBackground()
            dismissLiveActivity(with: model)
        }
    }
}
