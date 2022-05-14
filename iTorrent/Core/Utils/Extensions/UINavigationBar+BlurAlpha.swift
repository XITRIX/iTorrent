//
//  UINavigationBar+BlurAlpha.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 14.05.2022.
//

import UIKit

extension UINavigationBar {
    var blurAlpha: CGFloat {
        guard let navBar = subviews.first?.subviews.first
        else { return 1 }

        return navBar.alpha
    }
}
