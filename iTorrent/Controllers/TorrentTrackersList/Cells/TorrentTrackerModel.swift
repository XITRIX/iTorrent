//
//  TorrentTrackerModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 02.05.2022.
//

import Foundation
import MVVMFoundation
import TorrentKit

struct TorrentTrackerModel: Hashable {
    var url: String
    var message: String
    var seeds: Int
    var peers: Int
    var leeches: Int
    var working: Bool
    var verified: Bool

    init(with tracker: TorrentTracker) {
        url = tracker.trackerUrl
        seeds = tracker.seeders
        peers = tracker.peers
        leeches = tracker.leechs
        working = tracker.working
        verified = tracker.verified

        message = working ? "Working" : "Inactive"
        if verified { message += ", \("Verified")" }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
}

extension TorrentTrackerModel: HidableItem {
    var hidden: Bool { false }
}
