//
//  ThemedUICollectionViewCell.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 19.04.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

class ThemedUICollectionViewCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        themeUpdate()
    }

    func setup() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeUpdate), name: Themes.updateNotification, object: nil)
        themeUpdate()
    }

    @objc func themeUpdate() {
        let theme = Themes.current
        backgroundColor = theme.backgroundMain
    }
}
