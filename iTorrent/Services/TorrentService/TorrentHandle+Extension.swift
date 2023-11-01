//
//  TorrentHandle+Extension.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 31/10/2023.
//

import LibTorrent

extension TorrentHandle {
    var friendlyState: State {
        switch state {
        case .downloading:
            if isPaused { return .paused }
            else { return .downloading }
        default:
            return state
        }
    }
}

extension TorrentHandle.State {
    var name: String {
        switch self {
        case .checkingFiles:
            return "Prepairing"
        case .downloadingMetadata:
            return "Fetching metadata"
        case .downloading:
            return "Downloading"
        case .finished:
            return "Done"
        case .seeding:
            return "Seeding"
        case .checkingResumeData:
            return "Resuming"
        case .paused:
            return "Paused"
        @unknown default:
            return ""
        }
    }
}
