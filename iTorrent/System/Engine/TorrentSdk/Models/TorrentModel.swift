//
//  TorrentModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 30.03.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import Foundation

class TorrentModel: Equatable {
    var title: String = ""
    var state: TorrentState = .null
    var displayState: TorrentState = .null
    var hash: String = ""
    var creator: String = ""
    var comment: String = ""
    var progress: Float = 0
    var totalWanted: Int64 = 0
    var totalWantedDone: Int64 = 0
    var downloadRate: Int = 0
    var uploadRate: Int = 0
    var totalDownloadSession: Int64 = 0
    var totalDownload: Int64 = 0
    var totalUploadSession: Int64 = 0
    var totalUpload: Int64 = 0
    var numSeeds: Int = 0
    var numPeers: Int = 0
    var totalSize: Int64 = 0
    var totalDone: Int64 = 0
    var creationDate: Date?
    var addedDate: Date?
    var isPaused: Bool = false
    var isFinished: Bool = false
    var isSeed: Bool = false
    var seedMode: Bool = false
    var seedLimit: Int64 = 0
    var hasMetadata: Bool = false
    var numPieces: Int = 0
    var pieces: [Int] = []
    var sequentialDownload: Bool = false

    init(_ torrentInfo: TorrentInfo) {
        state = TorrentState(rawValue: String(validatingUTF8: torrentInfo.state) ?? "") ?? .null
        title = state == .metadata ? NSLocalizedString("Obtaining Metadata", comment: "") : String(validatingUTF8: torrentInfo.name) ?? "ERROR"
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
        pieces = Array(UnsafeBufferPointer(start: torrentInfo.pieces, count: numPieces)).map({Int($0)})

        if Core.shared.torrentsUserData[hash] == nil {
            Core.shared.torrentsUserData[hash] = UserManagerSettings()
        }
        addedDate = Core.shared.torrentsUserData[hash]?.addedDate
        seedMode = (Core.shared.torrentsUserData[hash]?.seedMode)!
        seedLimit = (Core.shared.torrentsUserData[hash]?.seedLimit)!

        Core.shared.torrentsUserData[hash]?.totalDownloadSession = totalDownloadSession
        Core.shared.torrentsUserData[hash]?.totalUploadSession = totalUploadSession

        totalDownload = Core.shared.torrentsUserData[hash]!.totalDownload
        totalUpload = Core.shared.torrentsUserData[hash]!.totalUpload

        displayState = getDisplayState()
    }
    
    func update(with model: TorrentModel) {
        let oldState = self.displayState
        
        state = model.state
        title = model.title
        creator = model.creator
        comment = model.comment
        progress = model.progress
        totalWanted = model.totalWanted
        totalWantedDone = model.totalWantedDone
        downloadRate = model.downloadRate
        uploadRate = model.uploadRate
        totalDownloadSession = model.totalDownloadSession
        totalUploadSession = model.totalUploadSession
        numSeeds = model.numSeeds
        numPeers = model.numPeers
        totalSize = model.totalSize
        totalDone = model.totalDone
        creationDate = model.creationDate
        isPaused = model.isPaused
        isFinished = model.isFinished
        isSeed = model.isSeed
        hasMetadata = model.hasMetadata

        sequentialDownload = model.sequentialDownload
        numPieces = model.numPieces
        pieces = model.pieces
        
        seedMode = (Core.shared.torrentsUserData[hash]?.seedMode)!
        seedLimit = (Core.shared.torrentsUserData[hash]?.seedLimit)!

        Core.shared.torrentsUserData[hash]?.totalDownloadSession = totalDownloadSession
        Core.shared.torrentsUserData[hash]?.totalUploadSession = totalUploadSession

        totalDownload = Core.shared.torrentsUserData[hash]!.totalDownload
        totalUpload = Core.shared.torrentsUserData[hash]!.totalUpload

        displayState = getDisplayState()
        
        if oldState != model.displayState {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .torrentsStateChanged,
                                                object: nil,
                                                userInfo: ["data": (manager: self, oldState: oldState, newState: model.displayState)])
            }
        }
    }

    private func getDisplayState() -> TorrentState {
        if state == .finished || state == .downloading,
            isFinished, !isPaused, seedMode {
            return .seeding
        }
        if state == .seeding, isPaused || !seedMode {
            return .finished
        }
        if state == .downloading, isFinished {
            return .finished
        }
        if state == .downloading, !isFinished, isPaused {
            return .paused
        }
        return state
    }

    func stateCorrector() {
        if displayState == .finished,
            !isPaused {
            stop_torrent(hash)
        } else if displayState == .seeding,
            totalUpload >= seedLimit,
            seedLimit != 0 {
            seedMode = false
            stop_torrent(hash)
        } else if state == .hashing, isPaused {
            start_torrent(hash)
        }
    }

    func checkSpeed() {
        guard let userData = Core.shared.torrentsUserData[hash] else {
            return
        }

        if displayState == .downloading,
            downloadRate <= 25000,
            BackgroundTask.backgrounding {
            userData.zeroSpeedTimeCounter += 1
        } else {
            userData.zeroSpeedTimeCounter = 0
        }

        if userData.zeroSpeedTimeCounter == UserPreferences.zeroSpeedLimit,
            UserPreferences.zeroSpeedLimit != 0 {
            NotificationHelper.showNotification(
                title: Localize.get("BackgroundTask.LowSpeed.Title") + "(\(Utils.getSizeText(size: Int64(downloadRate)))/s)",
                body: title + Localize.get("BackgroundTask.LowSpeed.Message"),
                hash: hash)
            BackgroundTask.checkToStopBackground()
        }
    }
    
    static func == (lhs: TorrentModel, rhs: TorrentModel) -> Bool {
        lhs.state == rhs.state &&
        lhs.hash == rhs.hash &&
        lhs.progress == rhs.progress &&
        lhs.totalWanted == rhs.totalWanted &&
        lhs.totalWantedDone == rhs.totalWantedDone &&
        lhs.downloadRate == rhs.downloadRate &&
        lhs.uploadRate == rhs.uploadRate &&
        lhs.totalDownloadSession == rhs.totalDownloadSession &&
        lhs.totalUploadSession == rhs.totalUploadSession &&
        lhs.numSeeds == rhs.numSeeds &&
        lhs.numPeers == rhs.numPeers &&
        lhs.totalDone == rhs.totalDone &&
        lhs.isPaused == rhs.isPaused &&
        lhs.isFinished == rhs.isFinished &&
        lhs.isSeed == rhs.isSeed &&
        lhs.hasMetadata == rhs.hasMetadata &&
        lhs.sequentialDownload == rhs.sequentialDownload &&
        lhs.pieces == rhs.pieces
    }
}
