//
//  TableHeaderView.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 08/01/2019.
//  Copyright © 2019  XITRIX. All rights reserved.
//

import UIKit

class TableHeaderView: UITableViewHeaderFooterView {
    @IBOutlet var title: ThemedUILabel!
    @IBOutlet var background: UIVisualEffectView!

    static func uiNib() -> UINib {
        UINib(nibName: "TableHeaderView", bundle: nil)
    }
}
