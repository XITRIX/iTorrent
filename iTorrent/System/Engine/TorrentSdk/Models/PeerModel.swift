//
//  PeerModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 28.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import Foundation
import DeepDiff

struct PeerModel: Hashable, DiffAware {
    var port: Int
    var client: String
    var totalDownload: Int64
    var totalUpload: Int64
    var upSpeed: Int
    var downSpeed: Int
    var connectionType: Int
    var progress: Int
    var progressPpm: Int
    var address: String
    
    init(_ model: Peer) {
        port = Int(model.port)
        client = String(validatingUTF8: model.client) ?? "ERROR"
        totalDownload = model.total_download
        totalUpload = model.total_upload
        upSpeed = Int(model.up_speed)
        downSpeed = Int(model.down_speed)
        connectionType = Int(model.connection_type)
        progress = Int(model.progress)
        progressPpm = Int(model.progress_ppm)
        address = String(validatingUTF8: model.address) ?? "ERROR"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(address)
    }
}
