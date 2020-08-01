//
//  TrackerModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 30.03.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import Foundation
import ITorrentFramework
import DeepDiff

struct TrackerModel: Hashable, DiffAware {
    var url: String
    var message: String
    var seeders: Int32
    var peers: Int32
    var leechs: Int32
    var working: Bool
    var verified: Bool
    
    init(_ tracker: Tracker) {
        url = String(cString: tracker.tracker_url)
        seeders = tracker.seeders
        peers = tracker.peers
        leechs = tracker.leechs
        working = tracker.working == 1
        verified = tracker.verified == 1
        message = working ? Localize.get("Working") : Localize.get("Inactive")
        if verified { message += ", \(Localize.get("Verified"))" }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
}
