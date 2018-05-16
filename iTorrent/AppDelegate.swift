//
//  AppDelegate.swift
//  iTorrent
//
//  Created by  XITRIX on 12.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        Manager.InitManager()
        
        if let splitViewController = window?.rootViewController as? UISplitViewController {
            splitViewController.delegate = self
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        save_fast_resume()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        let primaryNav = primaryViewController as? UINavigationController
        let secondNav = secondaryViewController as? UINavigationController
        if (secondNav != nil) {
            var viewControllers : [UIViewController] = []
            viewControllers += (primaryNav?.viewControllers)!
            viewControllers += (secondNav?.viewControllers)!
            primaryNav?.viewControllers = viewControllers
        }
        return true
    }

    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        if let nav = primaryViewController as? UINavigationController,
            nav.topViewController is SettingsController{
            return Utils.createEmptyViewController()
        }
        
        let controllers = splitViewController.viewControllers
        if let navController = controllers[controllers.count - 1] as? UINavigationController {
            var viewControllers : [UIViewController] = []
            while (!(navController.topViewController is MainController) &&
                   !(navController.topViewController is SettingsController)) {
                let view = navController.topViewController
                navController.popViewController(animated: false)
                viewControllers.append(view!)
            }
            viewControllers.reverse()
            
            if (viewControllers.count == 0) {
                return Utils.createEmptyViewController()
            }
            
            let detailNavController = UINavigationController()
            detailNavController.viewControllers = viewControllers
            detailNavController.setToolbarHidden(false, animated: false)
            detailNavController.navigationBar.tintColor = navController.navigationBar.tintColor
            detailNavController.toolbar.tintColor = navController.navigationBar.tintColor
            
            return detailNavController
        }
        return nil
    }

}

