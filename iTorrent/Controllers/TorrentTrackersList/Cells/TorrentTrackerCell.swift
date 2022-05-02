//
//  TorrentTrackerCell.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 02.05.2022.
//

import UIKit
import MVVMFoundation

class TorrentTrackerCell: MvvmTableViewCell {
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var messageLabel: UILabel!
    @IBOutlet private var seedersLabel: UILabel!
    @IBOutlet private var peersLabel: UILabel!
    @IBOutlet private var leechersLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.font = titleLabel.font.bold()
        messageLabel.font = messageLabel.font.bold()
    }

    func setup(with model: TorrentTrackerModel) {
        titleLabel.text = model.url
        messageLabel.text = model.message
        seedersLabel.text = "Seeds \(model.seeds)"
        peersLabel.text = "Peers \(model.peers)"
        leechersLabel.text = "Leechers \(model.leeches)"

        peersLabel.superview?.isHidden = model.leeches == -1 && model.seeds == -1 && model.peers == -1
    }
}
