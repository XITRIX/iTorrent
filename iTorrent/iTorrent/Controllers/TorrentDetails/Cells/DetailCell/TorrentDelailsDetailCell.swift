//
//  TorrentDelailsDetailCell.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 17.04.2022.
//

import MVVMFoundation
import UIKit

class TorrentDelailsDetailCell: MvvmTableViewCell {
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var detailLabel: UILabel!

    func setup(with model: TorrentDelailsDetailViewModel) {
        bind(in: reuseBag) {
            model.$title => titleLabel
            model.$detail => detailLabel
        }
    }
}
