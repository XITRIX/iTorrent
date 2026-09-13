//
//  UIScrollEdgeEffectStyle+Private.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 25.08.2026.
//

import UIKit

@available(iOS 27.0, *)
extension UIScrollEdgeEffect.Style {
    static var photos: UIScrollEdgeEffect.Style {
        let selectorString = "_photosStyle"
        let selector = NSSelectorFromString(selectorString)

        guard responds(to: selector) else { return .automatic }

        let type = (@convention(c) (AnyObject, Selector) -> UIScrollEdgeEffect.Style).self
        let method = unsafeBitCast(method(for: selector), to: type)
        return method(self, selector)
    }

    static var messages: UIScrollEdgeEffect.Style {
        let selectorString = "_messagesStyle"
        let selector = NSSelectorFromString(selectorString)

        guard responds(to: selector) else { return .automatic }

        let type = (@convention(c) (AnyObject, Selector) -> UIScrollEdgeEffect.Style).self
        let method = unsafeBitCast(method(for: selector), to: type)
        return method(self, selector)
    }
}
