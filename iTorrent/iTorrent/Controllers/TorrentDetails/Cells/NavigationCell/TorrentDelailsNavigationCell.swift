//
//  TorrentDelailsNavigationCell.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 21.04.2022.
//

import MVVMFoundation
import UIKit

class TorrentDelailsNavigationCell: MvvmTableViewCell {
    @IBOutlet private var titleLabel: UILabel!

    func setup(with model: TorrentDelailsNavigationViewModel) {
        bind(in: reuseBag) {
            model.$title => titleLabel
        }
    }
}
