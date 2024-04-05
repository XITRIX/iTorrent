//
//  UISwitchWithMenu.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 05/04/2024.
//

import UIKit

class UISwitchWithMenu: UISwitch {
    var menu: UIMenu? {
        didSet { isContextMenuInteractionEnabled = menu != nil }
    }

    override func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        .init(actionProvider: { [menu] _ in
            menu
        })
    }
}
