//
//  RssItemCell.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 06.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

class RssItemCell: ThemedUITableViewCell {
    static let id = "RssItemCell"
    static let nib = UINib(nibName: id, bundle: Bundle.main)

    @IBOutlet var updateDot: TintView!
    @IBOutlet var title: ThemedUILabel!
    @IBOutlet var date: ThemedUILabel!
    
    func setModel(_ model: RssItemModel) {
        title.colorType = model.readed ? .secondary : .primary
        title.text = model.title
        
        updateDot.isHidden = !model.new
        
        if let datet = model.date {
            let now = Date()
            date.isHidden = false
            date.text = now.offset(from: datet)
        } else {
            date.isHidden = true
        }
        
    }
}
