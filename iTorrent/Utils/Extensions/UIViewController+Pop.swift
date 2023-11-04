//
//  UIViewController+Pop.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 03/11/2023.
//

import UIKit

extension UIViewController {
    @objc func pop(animated: Bool, sender: Any? = nil) {
        if let parent {
            parent.pop(animated: animated, sender: sender ?? self)
        } else {
            dismiss()
        }
    }
}

extension UINavigationController {
    override func pop(animated: Bool, sender: Any? = nil) {
        guard popViewController(animated: animated) != nil
        else { return super.pop(animated: animated, sender: sender) }
    }
}
