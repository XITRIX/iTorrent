//
//  AppDelegate.swift
//  iTorrent
//
//  Created by  XITRIX on 12.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import UIKit

import Firebase
import GoogleMobileAds

#if !targetEnvironment(macCatalyst)
import AppCenter
import AppCenterAnalytics
import AppCenterCrashes
#endif

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    static var backgrounded = false
    var openedByFile = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)

        FirebaseApp.configure()
        GADMobileAds.sharedInstance().start(completionHandler: nil)

        // Crash on iOS 9
        if #available(iOS 10, *) {
            #if !targetEnvironment(macCatalyst)
            MSAppCenter.start("381c5088-264f-4ea2-b145-498a2ce15a06", withServices: [
                MSAnalytics.self,
                MSCrashes.self
            ])
            #endif
        }

        PatreonAPI.configure()

        DispatchQueue.global(qos: .utility).async {
            sleep(1)
            if !self.openedByFile {
                FullscreenAd.shared.load()
            }
        }

        Core.configure()

        if #available(iOS 13.0, *) {
            Themes.shared.currentUserTheme = window?.traitCollection.userInterfaceStyle.rawValue
        }

        if let splitViewController = window?.rootViewController as? UISplitViewController {
            splitViewController.delegate = self
            splitViewController.preferredDisplayMode = .allVisible
        }

        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                print("Granted: " + String(granted))
            }
            center.removeAllDeliveredNotifications()
            center.delegate = self
        } else {
            application.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil))
            UIApplication.shared.cancelAllLocalNotifications()
        }

        if UserPreferences.ftpKey {
            Core.shared.startFileSharing()
        }

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        print("Path: " + url.path)
        if url.absoluteString.hasPrefix("magnet:") {
            Core.shared.addMagnet(url.absoluteString)
        } else {
            openedByFile = true
            Core.shared.addTorrentFromFile(url)
        }

        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        Core.shared.saveTorrents()
        _ = BackgroundTask.startBackground()
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
        TorrentSdk.resumeToApp()
        AppDelegate.backgrounded = false
    }

    func applicationWillTerminate(_ application: UIApplication) {
        Core.shared.saveTorrents(filesStatesOnly: false)
    }

    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        RssFeedProvider.shared.fetchUpdates { updates in
            if updates.keys.count > 0 {
                let text = updates.keys
                    .filter { !$0.muteNotifications }
                    .map { updates[$0]! }
                    .reduce([], +)
                    .compactMap { $0.title }
                    .joined(separator: "\n")

                NotificationHelper.showNotification(title: Localize.get("RssFeedProvider.Notification.Title"),
                                                    body: text,
                                                    hash: "RSS")
                completionHandler(.newData)
            } else {
                completionHandler(.noData)
            }
        }
    }
}
