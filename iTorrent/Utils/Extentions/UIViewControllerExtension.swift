//
//  UIViewControllerExtension.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 23.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

extension UIViewController {
    func embedInNavController() -> UINavigationController {
        Utils.instantiateNavigationController(self)
    }
    
    func contentInsets() -> UIEdgeInsets {
        var insets = UIEdgeInsets()
        insets.top += min(navigationController?.navigationBar.frame.height ?? 0, 44) 
        insets.top += UIApplication.shared.statusBarFrame.height 
        return insets
    }
}
