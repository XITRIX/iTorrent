//
//  TorrentsListHeader.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 14.05.2022.
//

import UIKit

class TorrentsListHeader: UITableViewHeaderFooterView {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var background: UIVisualEffectView!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        if #available(iOS 14.0, *) {
            var backgroundConfig = UIBackgroundConfiguration.clear()
            backgroundConfig.backgroundColor = .clear
            backgroundConfiguration = backgroundConfig
        }
    }
}
