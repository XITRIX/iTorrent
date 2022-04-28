//
//  TorrentDirectoryCell.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 22.04.2022.
//

import MVVMFoundation
import UIKit

class TorrentDirectoryCell: MvvmTableViewCell {
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var sizeLabel: UILabel!
    @IBOutlet private var optionsButton: UIButton!

    var menu: UIMenu? {
        get { optionsButton.menu }
        set { optionsButton.menu = newValue }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        optionsButton.showsMenuAsPrimaryAction = true
    }

    func setup(with model: DirectoryEntity) {
        titleLabel.text = model.name
        sizeLabel.text = "\(Utils.Size.getSizeText(size: UInt(model.size)))"
    }
}
