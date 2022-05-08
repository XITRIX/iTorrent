//
//  TorrentHandleExtensions.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 25.04.2022.
//

import Foundation
import ReactiveKit
import TorrentKit


extension TorrentHandle {
    var displayState: State {
        if snapshot.state == .finished || snapshot.state == .downloading,
           snapshot.isFinished, !snapshot.isPaused, allowSeeding
        {
            return .seeding
        }
        if snapshot.state == .seeding, snapshot.isPaused || !allowSeeding {
            return .finished
        }
        if snapshot.state == .downloading, snapshot.isFinished {
            return .finished
        }
        if snapshot.state == .downloading, !snapshot.isFinished, snapshot.isPaused {
            return .paused
        }
        return snapshot.state
    }

    var canResume: Bool {
        snapshot.isPaused && (displayState != .finished || allowSeeding)
    }

    var canPause: Bool {
        !snapshot.isPaused
    }

    func localInit() {
        initLocalStorage()
        bind(in: bag) {
            rx.updateObserver.observeNext { $0.pauseIfNeeded() }
        }
    }

    func pauseIfNeeded() {
        if !snapshot.isPaused && displayState == .finished {
            pause()
        }
    }
}

extension TorrentHandle.State: CustomStringConvertible {
    public var description: String {
        switch self {
        case .checkingFiles: return "Checking Files"
        case .downloadingMetadata: return "Downloading Metadata"
        case .downloading: return "Downloading"
        case .finished: return "Finished"
        case .seeding: return "Seeding"
        case .allocating: return "Allocating"
        case .checkingResumeData: return "Checking Resume Data"
        case .paused: return "Paused"
        @unknown default: return "Unknown"
        }
    }

    public var symbol: String {
        switch self {
        case .downloading: return "↓"
        case .seeding: return "↑"
        default: return "*"
        }
    }
}
