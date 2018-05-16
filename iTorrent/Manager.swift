//
//  Manager.swift
//  iTorrent
//
//  Created by  XITRIX on 14.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation

class Manager {
    
    public static var torrentStates : [TorrentStatus] = []
    public static let rootFolder = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!;
    public static let configFolder = Manager.rootFolder + "/_Config"
    public static var managersUpdatedDelegates : [ManagersUpdatedDelegate] = []
    public static var managerAddedDelegates : [ManagerAddedDelegade] = []
    
    public static func InitManager() {
        DispatchQueue.global(qos: .background).async {
            init_engine(Manager.rootFolder)
            restoreAllTorrents()
            while(true) {
                updateTorrentsStatus()
                sleep(1)
            }
        }
    }
    
    static func restoreAllTorrents() {
        Utils.checkFolderExist(path: configFolder)
        if (FileManager.default.fileExists(atPath: configFolder+"/_temp.torrent")) {
            try! FileManager.default.removeItem(atPath: configFolder+"/_temp.torrent")
        }
        let files = try! FileManager.default.contentsOfDirectory(atPath: Manager.configFolder).filter({$0.hasSuffix(".torrent")})
        for file in files {
            addTorrent(configFolder + "/" + file)
        }
    }
    
    static func updateTorrentsStatus() {
        let res = getTorrentInfo()
        Manager.torrentStates.removeAll()
        let nameArr = Array(UnsafeBufferPointer(start: res.name, count: Int(res.count)))
        let stateArr = Array(UnsafeBufferPointer(start: res.state, count: Int(res.count)))
        var hashArr = Array(UnsafeBufferPointer(start: res.hash, count: Int(res.count)))
        let creatorArr = Array(UnsafeBufferPointer(start: res.creator, count: Int(res.count)))
        let commentArr = Array(UnsafeBufferPointer(start: res.comment, count: Int(res.count)))
        for i in 0 ..< Int(res.count) {
            let status = TorrentStatus()
            
            status.state = String(validatingUTF8: stateArr[Int(i)]!) ?? "ERROR"
            status.title = status.state == Utils.torrentStates.Metadata.rawValue ? "Obtaining Metadata" : String(validatingUTF8: nameArr[Int(i)]!) ?? "ERROR"
            status.hash = String(validatingUTF8: hashArr[Int(i)]!) ?? "ERROR"
            status.creator = String(validatingUTF8: creatorArr[Int(i)]!) ?? "ERROR"
            status.comment = String(validatingUTF8: commentArr[Int(i)]!) ?? "ERROR"
            status.progress = res.progress[i]
            status.totalWanted = res.total_wanted[i]
            status.totalWantedDone = res.total_wanted_done[i]
            status.downloadRate = Int(res.download_rate[i])
            status.uploadRate = Int(res.upload_rate[i])
            status.totalDownload = res.total_download[i]
            status.totalUpload = res.total_upload[i]
            status.numSeeds = Int(res.num_seeds[i])
            status.numPeers = Int(res.num_peers[i])
            status.totalSize = res.total_size[i]
            status.totalDone = res.total_done[i]
            status.creationDate = Date(timeIntervalSince1970: TimeInterval(res.creation_date[i]))
            
            Manager.torrentStates.append(status)
        }
        
        DispatchQueue.main.async {
            for i in Manager.managersUpdatedDelegates {
                i.managerUpdated();
            }
        }
    }
    
    static func addTorrent(_ filePath: String) {
        add_torrent(filePath)
        updateTorrentsStatus()
        DispatchQueue.main.async {
            for i in Manager.managerAddedDelegates {
                i.managerAdded();
            }
        }
    }
    
    static func addMagnet(_ magnetLink: String) {
        add_magnet(magnetLink)
        updateTorrentsStatus()
        DispatchQueue.main.async {
            for i in Manager.managerAddedDelegates {
                i.managerAdded();
            }
        }
    }
    
    static func getManagerByHash(hash: String) -> TorrentStatus? {
        return torrentStates.filter({$0.hash == hash}).first
    }
}
