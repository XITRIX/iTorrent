//
//  BackportIosApi.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 08.03.2022.
//  Copyright © 2022  XITRIX. All rights reserved.
//

import UIKit

extension UIView {
    var safeAreaInsetsBack: UIEdgeInsets {
        if #available(iOS 11, *) {
            return self.safeAreaInsets
        }
        return .zero
    }
}

