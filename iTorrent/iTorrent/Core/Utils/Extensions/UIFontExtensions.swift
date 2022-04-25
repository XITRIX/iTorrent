//
//  UIFontExtensions.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 06.08.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

extension UIFont {
    func withTraits(traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        let descriptor = fontDescriptor.withSymbolicTraits(traits)
        return UIFont(descriptor: descriptor!, size: 0) // size 0 means keep the size as it is
    }

    func normal() -> UIFont {
        withTraits(traits: [])
    }

    func bold() -> UIFont {
        withTraits(traits: .traitBold)
    }

    func italic() -> UIFont {
        withTraits(traits: .traitItalic)
    }
}
