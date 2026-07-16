//
//  TorrentHandle+Snapshot.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 10.06.2026.
//

import LibTorrent
import Perception

extension TorrentHandle {
    @Perceptible
    class ObservedSnapshot {
        private weak var torrentHandle: TorrentHandle?
        private var hasLoadedImmutableTorrentMetadata = false

        var isValid: Bool
        var infoHashes: TorrentHashes
        var name: String
        var state: TorrentHandle.State
        var creator: String?
        var comment: String?
        var creationDate: Date?
        var progress: Double
        var progressWanted: Double
        var numberOfPeers: UInt
        var numberOfSeeds: UInt
        var numberOfLeechers: UInt
        var numberOfTotalPeers: UInt
        var numberOfTotalSeeds: UInt
        var numberOfTotalLeechers: UInt
        var downloadRate: UInt64
        var uploadRate: UInt64
        var hasMetadata: Bool
        var total: UInt64
        var totalDone: UInt64
        var totalWanted: UInt64
        var totalWantedDone: UInt64
        var totalDownload: UInt64
        var totalUpload: UInt64
        var isPaused: Bool
        var isFinished: Bool
        var isSeed: Bool
        var isSequential: Bool
        var isFirstLastPiecePriority: Bool
        var isPrivate: Bool
        var pieces: [NSNumber]?
        var files: [FileEntry]
        var trackers: [TorrentTracker]
        var magnetLink: String
        var torrentFilePath: String?
        var downloadPath: URL?
        var storageUUID: UUID?
        var isStorageMissing: Bool

        init(with torrentHandle: TorrentHandle) {
            self.torrentHandle = torrentHandle

            let snapshot = torrentHandle.snapshot
            isValid = snapshot.isValid
            infoHashes = snapshot.infoHashes
            name = snapshot.name
            state = snapshot.state
            creator = snapshot.creator
            comment = snapshot.comment
            creationDate = snapshot.creationDate
            progress = snapshot.progress
            progressWanted = snapshot.progressWanted
            numberOfPeers = snapshot.numberOfPeers
            numberOfSeeds = snapshot.numberOfSeeds
            numberOfLeechers = snapshot.numberOfLeechers
            numberOfTotalPeers = snapshot.numberOfTotalPeers
            numberOfTotalSeeds = snapshot.numberOfTotalSeeds
            numberOfTotalLeechers = snapshot.numberOfTotalLeechers
            downloadRate = snapshot.downloadRate
            uploadRate = snapshot.uploadRate
            hasMetadata = snapshot.hasMetadata
            total = snapshot.total
            totalDone = snapshot.totalDone
            totalWanted = snapshot.totalWanted
            totalWantedDone = snapshot.totalWantedDone
            totalDownload = snapshot.totalDownload
            totalUpload = snapshot.totalUpload
            isPaused = snapshot.isPaused
            isFinished = snapshot.isFinished
            isSeed = snapshot.isSeed
            isSequential = snapshot.isSequential
            isFirstLastPiecePriority = snapshot.isFirstLastPiecePriority
            isPrivate = torrentHandle.isPrivate
            pieces = snapshot.pieces
            files = snapshot.files
            trackers = snapshot.trackers
            magnetLink = snapshot.magnetLink
            torrentFilePath = snapshot.torrentFilePath
            downloadPath = snapshot.downloadPath
            storageUUID = snapshot.storageUUID
            isStorageMissing = snapshot.isStorageMissing
            hasLoadedImmutableTorrentMetadata = snapshot.hasMetadata
        }

        func update() {
            guard let torrentHandle else { return }
            let snapshot = torrentHandle.snapshot

            isValid = snapshot.isValid
            if !hasLoadedImmutableTorrentMetadata {
                infoHashes = snapshot.infoHashes
                name = snapshot.name
                creator = snapshot.creator
                comment = snapshot.comment
                creationDate = snapshot.creationDate
                total = snapshot.total
                hasLoadedImmutableTorrentMetadata = snapshot.hasMetadata
            }
            state = snapshot.state
            progress = snapshot.progress
            progressWanted = snapshot.progressWanted
            numberOfPeers = snapshot.numberOfPeers
            numberOfSeeds = snapshot.numberOfSeeds
            numberOfLeechers = snapshot.numberOfLeechers
            numberOfTotalPeers = snapshot.numberOfTotalPeers
            numberOfTotalSeeds = snapshot.numberOfTotalSeeds
            numberOfTotalLeechers = snapshot.numberOfTotalLeechers
            downloadRate = snapshot.downloadRate
            uploadRate = snapshot.uploadRate
            hasMetadata = snapshot.hasMetadata
            totalDone = snapshot.totalDone
            totalWanted = snapshot.totalWanted
            totalWantedDone = snapshot.totalWantedDone
            totalDownload = snapshot.totalDownload
            totalUpload = snapshot.totalUpload
            isPaused = snapshot.isPaused
            isFinished = snapshot.isFinished
            isSeed = snapshot.isSeed
            isSequential = snapshot.isSequential
            isFirstLastPiecePriority = snapshot.isFirstLastPiecePriority
            isPrivate = torrentHandle.isPrivate
            pieces = snapshot.pieces
            files = snapshot.files
            trackers = snapshot.trackers
            magnetLink = snapshot.magnetLink
            torrentFilePath = snapshot.torrentFilePath
            downloadPath = snapshot.downloadPath
            storageUUID = snapshot.storageUUID
            isStorageMissing = snapshot.isStorageMissing
        }
    }
}

extension TorrentHandle {
    private enum Keys {
        nonisolated(unsafe) static var TorrentHandleObservedSnapshotKey: Void?
    }

    var observableSnapshot: ObservedSnapshot {
        guard let obj = objc_getAssociatedObject(self, &Keys.TorrentHandleObservedSnapshotKey) as? ObservedSnapshot
        else {
            objc_setAssociatedObject(self, &Keys.TorrentHandleObservedSnapshotKey, ObservedSnapshot(with: self), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            return objc_getAssociatedObject(self, &Keys.TorrentHandleObservedSnapshotKey) as! ObservedSnapshot
        }
        return obj
    }
}
