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
                self.alpha = newValue ? 0 : 1
            }
        }
    }

    var parentViewController: UIViewController? {
        // Starts from next (As we know self is not a UIViewController).
        var parentResponder: UIResponder? = self.next
        while parentResponder != nil {
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
            parentResponder = parentResponder?.next
        }
        return nil
    }
}

extension UIView {
    func parentView<T: UIView>(of type: T.Type) -> T? {
        guard let view = superview else {
            return nil
        }
        return (view as? T) ?? view.parentView(of: T.self)
    }
}

