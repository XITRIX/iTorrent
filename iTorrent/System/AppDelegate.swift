//
//  AppDelegate.swift
//  iTorrent
//
//  Created by  XITRIX on 12.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import UIKit
import UserNotifications

import Firebase
import GoogleMobileAds

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?

    static var backgrounded = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        GADMobileAds.sharedInstance().start(completionHandler: nil)

        Manager.initManager()

        if #available(iOS 13.0, *) {
            Themes.shared.currentUserTheme = window?.traitCollection.userInterfaceStyle.rawValue
        }

        if let splitViewController = window?.rootViewController as? UISplitViewController {
            splitViewController.delegate = self
            splitViewController.preferredDisplayMode = .allVisible
        }

        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
                print("Granted: " + String(granted))
            }
            center.removeAllDeliveredNotifications()
        } else {
            application.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil))
            UIApplication.shared.cancelAllLocalNotifications()
        }

        if (UserPreferences.ftpKey.value) {
            Manager.startFileSharing()
        }

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        print("Path: " + url.path)
        if (url.absoluteString.hasPrefix("magnet:")) {
            Manager.addMagnet(url.absoluteString)
        } else {
            Manager.addTorrentFromFile(url)
        }

        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        Manager.saveTorrents(filesStatesOnly: BackgroundTask.startBackground())
        AppDelegate.backgrounded = true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        } else {
            UIApplication.shared.cancelAllLocalNotifications()
        }
        UIApplication.shared.applicationIconBadgeNumber = 0
        BackgroundTask.stopBackgroundTask()
        resume_to_app()
        AppDelegate.backgrounded = false
    }

    func applicationWillTerminate(_ application: UIApplication) {
        Manager.saveTorrents()
    }

    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        let primaryNav = primaryViewController as? UINavigationController
        let secondNav = secondaryViewController as? UINavigationController
        if (secondNav != nil) {
            var viewControllers: [UIViewController] = []
            viewControllers += (primaryNav?.viewControllers)!
            viewControllers += (secondNav?.viewControllers)!
            primaryNav?.viewControllers = viewControllers
            primaryNav?.isToolbarHidden = false
        }
        return true
    }

    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        if let nav = primaryViewController as? UINavigationController {
            if nav.topViewController is PreferencesController || nav.topViewController is SettingsSortingController {
                return Utils.createEmptyViewController()
            }
        }

        let controllers = splitViewController.viewControllers
        if let navController = controllers[controllers.count - 1] as? UINavigationController {
            var viewControllers: [UIViewController] = []
            while (!(navController.topViewController is MainController) &&
                !(navController.topViewController is PreferencesController)) {
                let view = navController.topViewController
                navController.popViewController(animated: false)
                viewControllers.append(view!)
            }
            viewControllers.reverse()

            if (viewControllers.count == 0) {
                return Utils.createEmptyViewController()
            }

            let theme = Themes.current

            let detailNavController = ThemedUINavigationController()
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

    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        if (!AppDelegate.backgrounded) {
            return
        }

        while (!Manager.torrentsRestored) {
            sleep(1)
        }

        if let hash = notification.userInfo?["hash"] as? String,
           let splitViewController = UIApplication.shared.keyWindow?.rootViewController as? UISplitViewController,
           let viewController = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "Detail") as? TorrentDetailsController {
            viewController.managerHash = hash
            if (!splitViewController.isCollapsed) {
                if splitViewController.viewControllers.count > 1,
                   let nvc = splitViewController.viewControllers[1] as? UINavigationController {
                    nvc.show(viewController, sender: self)
                } else {
                    let navController = ThemedUINavigationController(rootViewController: viewController)
                    navController.isToolbarHidden = false
                    splitViewController.showDetailViewController(navController, sender: self)
                }
            } else {
                splitViewController.showDetailViewController(viewController, sender: self)
            }
        }
    }
}

