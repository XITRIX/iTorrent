//
//  UITableViewCellExtensions.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 25.03.2022.
//  Copyright © 2022  XITRIX. All rights reserved.
//

import UIKit

extension UITableViewCell {
    func getTableView() -> UITableView? {
         parentView(of: UITableView.self)
    }
}
