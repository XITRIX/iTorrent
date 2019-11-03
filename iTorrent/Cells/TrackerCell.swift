//
//  TrackerCell.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 02/07/2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import UIKit

class TrackerCell: ThemedUITableViewCell {

    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var message: UILabel!
    @IBOutlet weak var seeders: UILabel!
    @IBOutlet weak var peers: UILabel!
    @IBOutlet weak var leechers: UILabel!

    override func themeUpdate() {
        super.themeUpdate()
        let theme = Themes.current
        title?.textColor = theme.mainText
        message?.textColor = theme.secondaryText
        seeders?.textColor = theme.secondaryText
        peers?.textColor = theme.secondaryText
        leechers?.textColor = theme.secondaryText

        let bgColorView = UIView()
        bgColorView.backgroundColor = theme.backgroundSecondary
        selectedBackgroundView = bgColorView
    }

    func setModel(tracker: Tracker) {
        title.text = tracker.url
        message.text = tracker.message
        peers.text = "\(NSLocalizedString("Peers", comment: "")): \(tracker.peers)"
        seeders.text = "\(NSLocalizedString("Seeds", comment: "")): \(tracker.seeders)"
        leechers.text = "\(NSLocalizedString("Leechers", comment: "")): \(tracker.leechs)"

        peers.superview?.isHidden = tracker.leechs == -1 && tracker.seeders == -1 && tracker.peers == -1
    }
}
