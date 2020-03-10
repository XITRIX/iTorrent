//
//  UILabelExtentions.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 02.03.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

extension UILabel {
    var textWithFit: String? {
        get {
            self.text
        }
        set {
            self.text = newValue
            self.sizeToFit()
        }
    }
}
