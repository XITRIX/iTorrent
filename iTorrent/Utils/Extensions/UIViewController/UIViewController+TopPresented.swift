//
//  UIViewController+TopPresented.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 03/04/2024.
//

import UIKit

extension UIViewController {
    var topPresented: UIViewController {
        var presentedVC = self
        while let next = presentedVC.presentedViewController {
            presentedVC = next
        }
        return presentedVC
    }
}
