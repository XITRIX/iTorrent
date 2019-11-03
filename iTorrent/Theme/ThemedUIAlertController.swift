//
//  ThemedUIAlertController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 24/06/2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class ThemedUIAlertController: UIAlertController, Themed {
    private var visualEffectView: [UIVisualEffectView] {
        // We're on an iPad and visual effect view is in a different place.
        if let presentationController = presentationController, presentationController.responds(to: Selector(("popoverView"))), let view = presentationController.value(forKey: "popoverView") as? UIView {
            return view.recursiveSubviews.compactMap({ $0 as? UIVisualEffectView })
        }

        return view.recursiveSubviews.compactMap({ $0 as? UIVisualEffectView })
    }

    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if #available(iOS 13.0, *) {
        } else {
            visualEffectView.forEach({ $0.effect = UIBlurEffect(style: Themes.current.blurEffect) })
        }
    }

    func themeUpdate() {
        let theme = Themes.current

        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = UIUserInterfaceStyle(rawValue: theme.overrideUserInterfaceStyle!)!
        } else {
            visualEffectView.forEach({ $0.effect = UIBlurEffect(style: theme.blurEffect) })

            if let cancelBackgroundViewType = NSClassFromString("_UIAlertControlleriOSActionSheetCancelBackgroundView") as? UIView.Type {
                cancelBackgroundViewType.appearance().subviewsBackgroundColor = theme.actionCancelButtonColor
            }

            if let title = title {
                let titleFont: [NSAttributedString.Key: Any] = [.foregroundColor: preferredStyle == .alert ? theme.mainText : theme.secondaryText,
                                                                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17)]
                let attributedTitle = NSMutableAttributedString(string: title, attributes: titleFont)
                setValue(attributedTitle, forKey: "attributedTitle")
            }
            if let message = message {
                let messageFont: [NSAttributedString.Key: Any] = [.foregroundColor: preferredStyle == .alert ? theme.mainText : theme.secondaryText]
                let attributedMessage = NSMutableAttributedString(string: message, attributes: messageFont)
                setValue(attributedMessage, forKey: "attributedMessage")
            }
        }
        view.tintColor = theme.actionButtonColor
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        themeUpdate()
    }
}

fileprivate extension UIView {
    private struct AssociatedKey {
        static var subviewsBackgroundColor = "subviewsBackgroundColor"
    }

    @objc dynamic var subviewsBackgroundColor: UIColor? {
        get {
            objc_getAssociatedObject(self, &AssociatedKey.subviewsBackgroundColor) as? UIColor
        }

        set {
            objc_setAssociatedObject(self,
                &AssociatedKey.subviewsBackgroundColor,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            subviews.forEach {
                $0.backgroundColor = newValue
            }
        }
    }

    @objc dynamic var subviewsBackgroundColorNonVisualEffect: UIColor? {
        get {
            objc_getAssociatedObject(self, &AssociatedKey.subviewsBackgroundColor) as? UIColor
        }

        set {
            objc_setAssociatedObject(self,
                &AssociatedKey.subviewsBackgroundColor,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            subviews.forEach {
                if !($0 is UIVisualEffectView) {
                    $0.backgroundColor = newValue
                }
            }
        }
    }
}

extension UIView {
    var recursiveSubviews: [UIView] {
        var subviews = self.subviews.compactMap({ $0 })
        subviews.forEach {
            subviews.append(contentsOf: $0.recursiveSubviews)
        }
        return subviews
    }
}
