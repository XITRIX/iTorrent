//
//  TorrentHandle+Extensions.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 12.12.2025.
//

import LibTorrent

extension TorrentHandle {
    var modernSnapshot: TorrentSession.Handle.Snapshot {
        .init(snapshot)
    }
}

extension TorrentHandle.Snapshot {
    var timeRemains: String {
        TorrentSession.Handle.Snapshot(self).timeRemains
    }

    var segmentedProgress: [Double] {
        TorrentSession.Handle.Snapshot(self).segmentedProgress
    }
    
    var stateText: String {
        TorrentSession.Handle.Snapshot(self).stateText
    }
}

extension TorrentSession.Handle.Snapshot {
    var timeRemains: String {
        guard downloadRate > 0 else { return %"time.infinity" }
        guard totalWanted >= totalWantedDone else { return "Almost done" }
        return ((totalWanted - totalWantedDone) / downloadRate).timeString
    }

    var segmentedProgress: [Double] {
        if !pieces.isEmpty { return pieces.map(Double.init) }
        return [0]
    }

    var stateText: String {
        let state = friendlyState
        var text = "\(state.name)"

        if state == .downloading {
            text += " - ↓ \(downloadRate.bitrateToHumanReadable)/s"
            text += " - \(timeRemains)"
        } else if state == .seeding {
            text += " - ↑ \(uploadRate.bitrateToHumanReadable)/s"
        }

        return text
    }
}
