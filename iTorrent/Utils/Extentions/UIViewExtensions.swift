//
//  UIViewExtentions.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 21.04.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

extension UIView {
    var isHiddenInStackView: Bool {
        get {
            self.isHidden
        }
        set {
            if self.isHidden != newValue {
                self.isHidden = newValue
            }
        }
    }
}
