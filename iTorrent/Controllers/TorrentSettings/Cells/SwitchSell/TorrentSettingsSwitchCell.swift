//
//  TorrentSettingsSwitchCell.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 14.05.2022.
//

import MVVMFoundation
import UIKit

class TorrentSettingsSwitchCell: MvvmTableViewCell {
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var switchView: UISwitch!

    func setup(with model: TorrentSettingsSwitchViewModel) {
        bind(in: reuseBag) {
            model.$title => titleLabel
            model.$value <=> switchView.reactive.isOn
        }
    }
}
