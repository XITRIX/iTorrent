//
//  TorrentStatus.swift
//  iTorrent
//
//  Created by  XITRIX on 14.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation

class TorrentStatus {
    var title : String = ""
    var state : String = ""
    var displayState : String = ""
    var hash : String = ""
    var creator : String = ""
    var comment : String = ""
    var progress : Float = 0
    var totalWanted : Int64 = 0
    var totalWantedDone : Int64 = 0
    var downloadRate : Int = 0
    var uploadRate : Int = 0
    var totalDownloadSession : Int64 = 0
    var totalDownload : Int64 = 0
    var totalUploadSession : Int64 = 0
    var totalUpload : Int64 = 0
    var numSeeds : Int = 0
    var numPeers : Int = 0
    var totalSize : Int64 = 0
    var totalDone : Int64 = 0
    var creationDate : Date?
	var addedDate : Date?
    var isPaused : Bool = false
    var isFinished : Bool = false
    var isSeed : Bool = false
	var seedMode : Bool = false
	var seedLimit : Int64 = 0
	var hasMetadata : Bool = false
    var numPieces : Int = 0
    var pieces : [Int32] = []
    var sequentialDownload : Bool = false
    
    init(_ torrentInfo: TorrentInfo) {
        state = String(validatingUTF8: torrentInfo.state) ?? "ERROR"
        title = state == Utils.torrentStates.Metadata.rawValue ? NSLocalizedString("Obtaining Metadata", comment: "") : String(validatingUTF8: torrentInfo.name) ?? "ERROR"
        hash = String(validatingUTF8: torrentInfo.hash) ?? "ERROR"
        creator = String(validatingUTF8: torrentInfo.creator) ?? "ERROR"
        comment = String(validatingUTF8: torrentInfo.comment) ?? "ERROR"
        progress = torrentInfo.progress
        totalWanted = torrentInfo.total_wanted
        totalWantedDone = torrentInfo.total_wanted_done
        downloadRate = Int(torrentInfo.download_rate)
        uploadRate = Int(torrentInfo.upload_rate)
        totalDownloadSession = torrentInfo.total_download
        totalUploadSession = torrentInfo.total_upload
        numSeeds = Int(torrentInfo.num_seeds)
        numPeers = Int(torrentInfo.num_peers)
        totalSize = torrentInfo.total_size
        totalDone = torrentInfo.total_done
        creationDate = Date(timeIntervalSince1970: TimeInterval(torrentInfo.creation_date))
        isPaused = torrentInfo.is_paused == 1
        isFinished = torrentInfo.is_finished == 1
        isSeed = torrentInfo.is_seed == 1
        hasMetadata = torrentInfo.has_metadata == 1
        
        sequentialDownload = torrentInfo.sequential_download == 1
        numPieces = Int(torrentInfo.num_pieces)
        pieces = Array(UnsafeBufferPointer(start: torrentInfo.pieces, count: numPieces))
        
        if (Manager.managerSaves[hash] == nil) {
            Manager.managerSaves[hash] = UserManagerSettings()
        }
        addedDate = Manager.managerSaves[hash]?.addedDate
        seedMode = (Manager.managerSaves[hash]?.seedMode)!
        seedLimit = (Manager.managerSaves[hash]?.seedLimit)!
        
        Manager.managerSaves[hash]?.totalDownloadSession = totalDownloadSession
        Manager.managerSaves[hash]?.totalUploadSession = totalUploadSession
        
        totalDownload = Manager.managerSaves[hash]!.totalDownload
        totalUpload = Manager.managerSaves[hash]!.totalUpload
        
        displayState = getDisplayState()
    }
    
    private func getDisplayState() -> String {
        if ((state == Utils.torrentStates.Finished.rawValue || state == Utils.torrentStates.Downloading.rawValue) &&
            isFinished && !isPaused && seedMode)
        {
            return Utils.torrentStates.Seeding.rawValue
        }
        if (state == Utils.torrentStates.Seeding.rawValue && (isPaused || !seedMode))
        {
            return Utils.torrentStates.Finished.rawValue
        }
        if (state == Utils.torrentStates.Downloading.rawValue && isFinished)
        {
            return Utils.torrentStates.Finished.rawValue
        }
        if (state == Utils.torrentStates.Downloading.rawValue && !isFinished && isPaused)
        {
            return Utils.torrentStates.Paused.rawValue
        }
        return state
    }
    
    func stateCorrector() {
        if (displayState == Utils.torrentStates.Finished.rawValue &&
            !isPaused)
        {
            stop_torrent(hash)
        }
        else if (displayState == Utils.torrentStates.Seeding.rawValue &&
            totalUpload >= seedLimit &&
            seedLimit != 0)
        {
            seedMode = false
            stop_torrent(hash)
        }
        else if (state == Utils.torrentStates.Hashing.rawValue && isPaused)
        {
            start_torrent(hash)
        }
    }
}
