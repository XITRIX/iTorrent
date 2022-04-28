//
//  UISwitchWithMenu.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 28.04.2022.
//

import UIKit

class UISwitchWithMenu: UISwitch {
    var menu: UIMenu?

    override func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { [unowned self] _ in
            menu
        })
    }
}
