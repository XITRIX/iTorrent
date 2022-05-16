//
//  TorrentSettingsActionCell.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 15.05.2022.
//

import MVVMFoundation
import UIKit

class TorrentSettingsActionCell: MvvmTableViewCell {
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var detailLabel: UILabel!

    func setup(with model: TorrentSettingsActionViewModel) {
        bind(in: reuseBag) {
            model.$title => titleLabel
            model.$detail => detailLabel
        }
    }
}
