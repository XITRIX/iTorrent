//
//  TrackerCell.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 02/07/2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

#if TRANSMISSION
import ITorrentTransmissionFramework
#else
import ITorrentFramework
#endif

import UIKit

class TrackerCell: ThemedUITableViewCell {
    @IBOutlet var title: UILabel!
    @IBOutlet var message: UILabel!
    @IBOutlet var seeders: UILabel!
    @IBOutlet var peers: UILabel!
    @IBOutlet var leechers: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        title.font = title.font.bold()
        message.font = message.font.bold()
    }

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

    func setModel(tracker: TrackerModel) {
        title.text = tracker.url
        message.text = tracker.message
        peers.text = "\(NSLocalizedString("Peers", comment: "")): \(tracker.peers)"
        seeders.text = "\(NSLocalizedString("Seeds", comment: "")): \(tracker.seeders)"
        leechers.text = "\(NSLocalizedString("Leechers", comment: "")): \(tracker.leechs)"

        peers.superview?.isHidden = tracker.leechs == -1 && tracker.seeders == -1 && tracker.peers == -1
    }
}
