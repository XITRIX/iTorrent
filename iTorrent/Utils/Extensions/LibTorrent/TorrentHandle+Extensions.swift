//
//  TorrentHandle+Extensions.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 12.12.2025.
//

import LibTorrent

extension TorrentHandle.Snapshot {
    var timeRemains: String {
        guard downloadRate > 0 else { return %"time.infinity" }
        guard totalWanted >= totalWantedDone else { return "Almost done" }
        return ((totalWanted - totalWantedDone) / downloadRate).timeString
    }

    var segmentedProgress: [Double] {
        pieces?.map { $0.doubleValue } ?? [0]
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
