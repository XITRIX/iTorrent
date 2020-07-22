//
//  PatronNameCell.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 20.04.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

class PatronNameCell: ThemedUICollectionViewCell {
    @IBOutlet var title: ThemedUILabel!
    
    override func themeUpdate() {
        let theme = Themes.current
        backgroundColor = theme.backgroundMain
    }
}
