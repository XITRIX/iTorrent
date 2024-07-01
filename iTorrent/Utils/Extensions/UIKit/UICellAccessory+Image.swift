//
//  UICellAccessory+Image.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 05.07.2024.
//

import UIKit

extension UICellAccessory {
    public struct ImageOptions {
        public var isHidden: Bool = false
        public var tintColor: UIColor? = nil
    }

    static func image(_ image: UIImage?, displayed: UICellAccessory.DisplayedState = .always, options: ImageOptions = .init()) -> UICellAccessory {
        .customView(configuration: .init(customView: {
            if let tintColor = options.tintColor {
                return UIImageView(image: image?.withTintColor(tintColor, renderingMode: .alwaysOriginal))
            } else {
                return UIImageView(image: image)
            }
        }(), placement: .trailing(displayed: displayed, at: { _ in 0 })))
    }
}
