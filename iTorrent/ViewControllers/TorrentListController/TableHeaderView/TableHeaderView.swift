//
//  TableHeaderView.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 08/01/2019.
//  Copyright © 2019  XITRIX. All rights reserved.
//

import UIKit

class TableHeaderView: UITableViewHeaderFooterView, Themed {
    static let id = "TableHeaderView"
    static let nib = UINib(nibName: id, bundle: Bundle.main)
    
    @IBOutlet var title: ThemedUILabel!
    @IBOutlet var background: UIVisualEffectView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        NotificationCenter.default.addObserver(self, selector: #selector(themeUpdate), name: Themes.updateNotification, object: nil)
        themeUpdate()
    }
    
    @objc func themeUpdate() {
        background.effect = UIBlurEffect(style: Themes.current.blurEffect)
        if #available(iOS 14, *) {
            background.backgroundColor = Themes.current.sectionHeaderColor
        }
    }
}
