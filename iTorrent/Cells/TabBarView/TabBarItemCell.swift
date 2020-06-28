//
//  TabBarItemCell.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 28.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

class TabBarItemCell: ThemedUICollectionViewCell {
    static let id = "TabBarItemCell"
    static let nib = UINib(nibName: id, bundle: Bundle.main)

    @IBOutlet var title: UILabel!
    private var _selected = false
    
    override func themeUpdate() {
        super.themeUpdate()
        backgroundColor = .clear
        setTitleColor()
    }
    
    func setTitleColor() {
        let theme = Themes.current
        title?.textColor = _selected ? theme.mainText : theme.secondaryText
    }
    
    func setModel(_ title: String, _ selected: Bool) {
        self.title?.text = title
        _selected = selected
        setTitleColor()
    }
    
    func setSelected(_ selected: Bool) {
        _selected = selected
        setTitleColor()
    }
}
