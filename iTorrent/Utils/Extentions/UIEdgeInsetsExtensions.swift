//
//  UIEdgeInsetsExtensions.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 15.11.2022.
//  Copyright © 2022  XITRIX. All rights reserved.
//

import UIKit

extension UIEdgeInsets {
    @available(iOS 11.0, *)
    init(_ insets: NSDirectionalEdgeInsets) {
        self.init(top: insets.top, left: insets.leading, bottom: insets.bottom, right: insets.trailing)
    }
}

@available(iOS 11.0, *)
extension NSDirectionalEdgeInsets {
    @available(iOS 11.0, *)
    init(_ insets: UIEdgeInsets) {
        self.init(top: insets.top, leading: insets.left, bottom: insets.bottom, trailing: insets.right)
    }
}
