//
//  RssSearchCell.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 20.10.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

class RssSearchCell: UITableViewCell {
    static let id = "RssSearchCell"
    static let nib = UINib(nibName: id, bundle: Bundle.main)
    
    @IBOutlet var title: ThemedUILabel!
    @IBOutlet var descriptionText: ThemedUILabel!
    @IBOutlet var date: ThemedUILabel!
    @IBOutlet var imageFav: UIImageView!
}
