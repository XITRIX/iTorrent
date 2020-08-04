//
//  TorrentCell.swift
//  iTorrent
//
//  Created by  XITRIX on 14.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import ITorrentFramework
import UIKit

class TorrentCell: ThemedUITableViewCell, UpdatableModel {
    @IBOutlet var title: UILabel!
    @IBOutlet var info: UILabel!
    @IBOutlet var status: UILabel!
    @IBOutlet var progress: UIProgressView!

    var model: TorrentModel!

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

    func updateModel() {
        title.text = model.title
        progress.progress = model.progress
        info.text = Utils.getSizeText(size: model.totalWantedDone) +
            " \(NSLocalizedString("of", comment: "")) " +
            Utils.getSizeText(size: model.totalWanted) +
            " (" + String(format: "%.2f", model.progress * 100) + "%)"
        if model.displayState == .downloading {
            status.text = NSLocalizedString(model.displayState.rawValue, comment: "") +
                " - DL:" + Utils.getSizeText(size: Int64(model.downloadRate)) +
                "/s - \(NSLocalizedString("time remains", comment: "")): " +
                Utils.downloadingTimeRemainText(speedInBytes: Int64(model.downloadRate), fileSize: model.totalWanted, downloadedSize: model.totalWantedDone)
        } else if model.displayState == .seeding {
            status.text = NSLocalizedString(model.displayState.rawValue, comment: "") +
                " - UL:" + Utils.getSizeText(size: Int64(model.uploadRate)) + "/s"
        } else {
            status.text = NSLocalizedString(model.displayState.rawValue, comment: "")
        }
    }
    
    func setModel(_ model: TorrentModel) {
        self.model = model
        updateModel()
    }
}
