//
//  UINavigationControllerExtensions.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 25.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

extension UINavigationController {
    func swizzle() {
        let method = class_getInstanceMethod(object_getClass(self),
                                             Selector(("_scrollOffsetRetargettedToDetentOffsetIfNecessary:unclampedOriginalTargetOffset:scrollView:")))

        let swizzledMethod = class_getInstanceMethod(object_getClass(self),
                                         #selector(swizzleM(_:unclampedOriginalTargetOffset:scrollView:)))

        if let method = method,
            let swizzledMethod = swizzledMethod {
            method_exchangeImplementations(method, swizzledMethod)
        }
    }

    @objc func swizzleM(_ arg1: Double, unclampedOriginalTargetOffset arg2: Double, scrollView arg3: UIScrollView) -> Double {
        let top = Double(arg3.contentInset.top)
        let res = swizzleM(arg1 + top, unclampedOriginalTargetOffset: arg2 + top, scrollView: arg3)
        return res - top
    }
}
