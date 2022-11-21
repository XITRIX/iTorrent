//
//  Utils+ViewController.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 21.11.2022.
//  Copyright © 2022  XITRIX. All rights reserved.
//

import UIKit

extension Utils {
    public static var safeAreaInsets: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return UIApplication.shared.keyWindow?.safeAreaInsets ?? .zero
        }
        return .zero
    }

    public static var topViewController: UIViewController? {
        var vc = UIApplication.shared.keyWindow?.rootViewController
        while vc?.presentedViewController != nil {
            vc = vc?.presentedViewController
        }
        return vc
    }

    public static var rootViewController: UIViewController {
        UIApplication.shared.keyWindow!.rootViewController!
    }

    public static var splitViewController: UISplitViewController? {
        rootViewController as? UISplitViewController
    }

    public static var mainStoryboard: UIStoryboard = {
        UIStoryboard(name: "Main", bundle: nil)
    }()

    public static func instantiate<T: UIViewController>(_ viewController: String) -> T {
        mainStoryboard.instantiateViewController(withIdentifier: viewController) as! T
    }

    public static func instantiateNavigationController(_ rootViewController: UIViewController? = nil) -> UINavigationController {
        let nvc = instantiate("NavigationController") as UINavigationController
        if let vc = rootViewController {
            nvc.viewControllers = [vc]
        }
        return nvc
    }

    public static func createEmptyViewController() -> UIViewController {
        let view = ThemedUIViewController()
        return view
    }

    public static func openUrl(_ url: String) {
        if let url = URL(string: url) {
            if #available(iOS 10, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }
}
