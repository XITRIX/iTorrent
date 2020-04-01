//
//  Core.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 30.03.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import Foundation
import GCDWebServer

class Core {
    public static let shared = Core()
    
    var state: CoreState = .Initializing
    
    var torrents: [String: TorrentModel] = [:]
    var torrentsUserData: [String: UserManagerSettings] = [:]
    
    let webUploadServer = GCDWebUploader(uploadDirectory: Core.rootFolder)
    let webDAVServer = GCDWebDAVServer(uploadDirectory: Core.rootFolder)
    
    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(managerStateChanged(notfication:)), name: .torrentsStateChanged, object: nil)
        
        DispatchQueue.global(qos: .background).async {
            TorrentSdk.initEngine(downloadFolder: Core.rootFolder, configFolder: Core.configFolder)
            self.restoreAllTorrents()

            let down = UserPreferences.downloadLimit.value
            TorrentSdk.setDownloadLimit(limitBytes: Int(down))

            let up = UserPreferences.uploadLimit.value
            TorrentSdk.setUploadLimits(limitBytes: Int(up))
            
            let allocateStorage = UserPreferences.storagePreallocation.value
            TorrentSdk.setStoragePreallocation(allocate: allocateStorage)
            
            self.state = .InProgress

            while true {
                self.mainLoop()
                sleep(1)
            }
        }
    }
    
    func mainLoop() {
        // update torrents states
        let res = TorrentSdk.getTorrents()
        for torrent in res {
            if let t = torrents[torrent.hash] {
                t.update(with: torrent)
            } else {
                torrents[torrent.hash] = torrent
            }

            torrent.stateCorrector()
        }
        
        // remove removed torrents
        let removed = torrents.values.filter {!res.contains($0)}
        for file in removed {
            torrents[file.hash] = nil
        }

        // check torrents speed to stop if == 0
        for torrent in torrents.values {
            torrent.checkSpeed()
        }

        // notify to update UI
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .mainLoopTick, object: nil)
        }
    }
}
