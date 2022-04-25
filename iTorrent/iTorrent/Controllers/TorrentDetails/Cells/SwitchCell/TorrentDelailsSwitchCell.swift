//
//  TorrentDelailsSwitchCell.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 18.04.2022.
//

import UIKit
import MVVMFoundation

class TorrentDelailsSwitchCell: MvvmTableViewCell {
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var switchView: UISwitch!

    func setup(with model: TorrentDelailsSwitchViewModel) {
        bind(in: reuseBag) {
            model.$title => titleLabel
            model.$value <=> switchView.reactive.isOn
        }
    }
}
