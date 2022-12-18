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
        setupFont()
        
        if #available(iOS 14.0, *) {
            var backgroundConfig = UIBackgroundConfiguration.clear()
            backgroundConfig.backgroundColor = .clear
            backgroundConfiguration = backgroundConfig
        }
        
        if #available(iOS 15.0, *) {
            background.alpha = 0
        }
    }
    
    @objc func themeUpdate() {
        background.effect = UIBlurEffect(style: Themes.current.blurEffect)
    }

    func setupFont() {
        let font = UIFont.systemFont(ofSize: 15)
        if #available(iOS 11.0, *) {
            let fontMetrics = UIFontMetrics(forTextStyle: .body)
            title.font = fontMetrics.scaledFont(for: font)
        }
    }
}
