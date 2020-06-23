//
//  AppDelegate+SplitViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 14.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

extension AppDelegate: UISplitViewControllerDelegate {
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        let primaryNav = primaryViewController as? UINavigationController
        let secondNav = secondaryViewController as? UINavigationController
        if let secondNav = secondNav {
            var viewControllers: [UIViewController] = []
            viewControllers += primaryNav!.viewControllers
            viewControllers += secondNav.viewControllers
            primaryNav?.viewControllers = viewControllers
            primaryNav?.isToolbarHidden = secondNav.isToolbarHidden
        }
        return true
    }

    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        if let nav = primaryViewController as? UINavigationController {
            if nav.topViewController is PreferencesController ||
                nav.topViewController is SortingPreferencesController ||
                nav.topViewController is WebDavPreferencesController ||
                nav.topViewController is PatreonViewController ||
                nav.topViewController is RssFeedController ||
                nav.topViewController is RssChannelController ||
                nav.topViewController is NetworkPreferencesController ||
                nav.topViewController is ProxyPreferencesController {
                return Utils.createEmptyViewController()
            }
        }

        let controllers = splitViewController.viewControllers
        if let navController = controllers[controllers.count - 1] as? UINavigationController {
            var viewControllers: [UIViewController] = []
            while !(navController.topViewController is TorrentListController),
                !(navController.topViewController is PreferencesController),
                !(navController.topViewController is SortingPreferencesController),
                !(navController.topViewController is WebDavPreferencesController),
                !(navController.topViewController is PatreonViewController),
                !(navController.topViewController is RssFeedController),
                !(navController.topViewController is RssChannelController),
                !(navController.topViewController is NetworkPreferencesController),
                !(navController.topViewController is ProxyPreferencesController) {
                let view = navController.topViewController
                navController.popViewController(animated: false)
                viewControllers.append(view!)
            }
            viewControllers.reverse()

            if viewControllers.count == 0 {
                return Utils.createEmptyViewController()
            }

            let theme = Themes.current

            let detailNavController = Utils.instantiateNavigationController()
            detailNavController.viewControllers = viewControllers
            detailNavController.setToolbarHidden(false, animated: false)
            detailNavController.navigationBar.barStyle = theme.barStyle
            detailNavController.toolbar.barStyle = theme.barStyle
            detailNavController.navigationBar.tintColor = navController.navigationBar.tintColor
            detailNavController.toolbar.tintColor = navController.navigationBar.tintColor

            return detailNavController
        }
        return nil
    }
}
