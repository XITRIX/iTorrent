//
//  TorrentCell.swift
//  iTorrent
//
//  Created by  XITRIX on 14.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import UIKit

class TorrentCell: UITableViewCell {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var info: UILabel!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var progress: UIProgressView!
    
    var manager: TorrentStatus!
    var indexPath : IndexPath!
    
    func update() {
        title.text = manager.title
        progress.progress = manager.progress
        info.text = Utils.getSizeText(size: manager.totalWantedDone) + " of " + Utils.getSizeText(size: manager.totalWanted) + " (" + String(format: "%.2f", manager.progress * 100) + "%)"
        if (manager.displayState == Utils.torrentStates.Downloading.rawValue) {
            status.text = manager.displayState + " - DL:" + Utils.getSizeText(size: Int64(manager.downloadRate)) + "/s - time remains: " + Utils.downloadingTimeRemainText(speedInBytes: Int64(manager.downloadRate), fileSize: manager.totalWanted, downloadedSize: manager.totalWantedDone)
        } else if (manager.displayState == Utils.torrentStates.Seeding.rawValue) {
            status.text = manager.displayState + " - UL:" + Utils.getSizeText(size: Int64(manager.uploadRate)) + "/s"
        } else {
            status.text = manager.displayState
        }
    }
}
