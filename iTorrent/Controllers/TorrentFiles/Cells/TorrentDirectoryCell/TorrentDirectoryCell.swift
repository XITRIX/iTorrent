//
//  TorrentDirectoryCell.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 22.04.2022.
//

import UIKit
import MVVMFoundation

class TorrentDirectoryCell: MvvmTableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var sizeLabel: UILabel!

    func setup(with model: DirectoryEntity) {
        titleLabel.text = model.name
        sizeLabel.text = "\(Utils.Size.getSizeText(size: UInt(model.size), decimals: 2))"
    }
}
