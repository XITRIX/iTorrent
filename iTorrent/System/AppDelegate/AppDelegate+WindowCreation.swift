//
//  AppDelegate+WindowCreation.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 05.08.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

extension AppDelegate {
    static func createWindow() -> UIWindow? {
        if #available(iOS 13.0, *) {
            let windowScene = UIApplication.shared
                .connectedScenes
                .first
            if let windowScene = windowScene as? UIWindowScene {
                return UIWindow(windowScene: windowScene)
            }
        } else {
            return UIWindow(frame: UIScreen.main.bounds)
        }
        return nil
    }

    func rootWindowInit() {
        self.window = AppDelegate.createWindow()
        window?.tintColor = .mainColor

        let nvc = Utils.instantiate("TorrentListController").embedInNavigation()
        if #available(iOS 11.0, *) {
            nvc.navigationBar.prefersLargeTitles = true
        }
        let svc = SplitViewController()
        svc.viewControllers = [nvc]
        window?.rootViewController = svc
        window?.makeKeyAndVisible()

        svc.delegate = self
        svc.preferredDisplayMode = .allVisible
    }
}
