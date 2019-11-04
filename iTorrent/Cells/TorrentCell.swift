//
//  TorrentCell.swift
//  iTorrent
//
//  Created by  XITRIX on 14.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import UIKit

class TorrentCell: ThemedUITableViewCell {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var info: UILabel!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var progress: UIProgressView!

    var manager: TorrentStatus!

    override func themeUpdate() {
        super.themeUpdate()
        let theme = Themes.current
        title?.textColor = theme.mainText
        info?.textColor = theme.secondaryText
        status?.textColor = theme.secondaryText

        let bgColorView = UIView()
        bgColorView.backgroundColor = theme.backgroundSecondary
        selectedBackgroundView = bgColorView
    }

    func update() {
        themeUpdate()
        title.text = manager.title
        progress.progress = manager.progress
        info.text = Utils.getSizeText(size: manager.totalWantedDone) +
            " \(NSLocalizedString("of", comment: "")) " +
            Utils.getSizeText(size: manager.totalWanted) +
            " (" + String(format: "%.2f", manager.progress * 100) + "%)"
        if manager.displayState == Utils.TorrentStates.downloading.rawValue {
            status.text = NSLocalizedString(manager.displayState, comment: "") +
                " - DL:" + Utils.getSizeText(size: Int64(manager.downloadRate)) +
                "/s - \(NSLocalizedString("time remains", comment: "")): " +
                Utils.downloadingTimeRemainText(speedInBytes: Int64(manager.downloadRate), fileSize: manager.totalWanted, downloadedSize: manager.totalWantedDone)
        } else if manager.displayState == Utils.TorrentStates.seeding.rawValue {
            status.text = NSLocalizedString(manager.displayState, comment: "") +
                " - UL:" + Utils.getSizeText(size: Int64(manager.uploadRate)) + "/s"
        } else {
            status.text = NSLocalizedString(manager.displayState, comment: "")
        }
    }
}
