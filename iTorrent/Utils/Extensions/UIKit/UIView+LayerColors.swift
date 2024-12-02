//
//  BaseView.swift
//  ReManga
//
//  Created by Даниил Виноградов on 02.06.2023.
//

import UIKit

public extension UIView {
    private enum Keys {
        nonisolated(unsafe) static var borderColorAssociateKey: Void?
        nonisolated(unsafe) static var shadowColorAssociateKey: Void?
    }

    var borderColor: UIColor? {
        get {
            objc_getAssociatedObject(self, &Keys.borderColorAssociateKey) as? UIColor
        }
        set {
            objc_setAssociatedObject(self, &Keys.borderColorAssociateKey, newValue, .OBJC_ASSOCIATION_RETAIN)
            layer.borderColor = newValue?.cgColor
        }
    }

    var shadowColor: UIColor? {
        get {
            objc_getAssociatedObject(self, &Keys.shadowColorAssociateKey) as? UIColor
        }
        set {
            objc_setAssociatedObject(self, &Keys.shadowColorAssociateKey, newValue, .OBJC_ASSOCIATION_RETAIN)
            layer.shadowColor = newValue?.cgColor
        }
    }

    static func enableUIColorsToLayer() {
        let aClass: AnyClass = object_getClass(UIView())!

        if let orig = class_getInstanceMethod(aClass, #selector(traitCollectionDidChange(_:))),
           let new = class_getInstanceMethod(aClass, #selector(swzl_traitCollectionDidChange(_:)))
        { method_exchangeImplementations(orig, new) }

        if let orig = class_getInstanceMethod(aClass, #selector(tintColorDidChange)),
           let new = class_getInstanceMethod(aClass, #selector(swzl_tintColorDidChange))
        { method_exchangeImplementations(orig, new) }
    }

    @objc private func swzl_traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        swzl_traitCollectionDidChange(previousTraitCollection)

        guard let previousTraitCollection,
              previousTraitCollection.hasDifferentColorAppearance(comparedTo: traitCollection)
        else { return }

        layer.borderColor = borderColor?.cgColor
        layer.shadowColor = shadowColor?.cgColor
    }

    @objc private func swzl_tintColorDidChange() {
        swzl_tintColorDidChange()

        if borderColor == .tintColor {
            layer.borderColor = borderColor?.cgColor
        }

        if shadowColor == .tintColor {
            layer.borderColor = borderColor?.cgColor
        }
    }
}
