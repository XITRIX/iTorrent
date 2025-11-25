//
//  UIImage+IOSRelatedIcons.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 25.11.2025.
//

import UIKit

extension UIImage {
    static var systemEllipsis: Self {
        if #available(iOS 26, *) {
            .init(systemName: "ellipsis")!
        } else {
            .init(systemName: "ellipsis.circle")!
        }
    }
}
