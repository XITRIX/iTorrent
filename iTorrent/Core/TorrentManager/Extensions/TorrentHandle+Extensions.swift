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
        if state == .finished || state == .downloading,
           isFinished, !isPaused, allowSeeding
        {
            return .seeding
        }
        if state == .seeding, isPaused || !allowSeeding {
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

    var canResume: Bool {
        isPaused && (displayState != .finished || allowSeeding)
    }

    var canPause: Bool {
        !isPaused
    }

    func localInit() {
        initLocalStorage()
        bind(in: bag) {
            rx.updateObserver.observeNext { $0.pauseIfNeeded() }
        }
    }

    func pauseIfNeeded() {
        if !isPaused && displayState == .finished {
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
