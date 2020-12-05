//
//  AppDelegate.swift
//  iTorrent
//
//  Created by  XITRIX on 12.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import AdSupport
import AppTrackingTransparency
import ITorrentFramework
import UIKit
// import ObjectiveC

#if !targetEnvironment(macCatalyst)
import Firebase
import GoogleMobileAds

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
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
//        ObjC.oldOSPatch()

        #if !targetEnvironment(macCatalyst)
        // Crash on iOS 9
        if #available(iOS 10, *) {
            AppCenter.start(withAppSecret: "381c5088-264f-4ea2-b145-498a2ce15a06", services: [
                Analytics.self,
                Crashes.self
            ])
        }

        FirebaseApp.configure()
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        // GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [ "0e836d6d9e4873bf2acac60f6e5de207" ]
        #endif

        pushNotificationsInit(application)
        PatreonAPI.configure()
        rootWindowInit()
        Core.configure()

        if #available(iOS 13.0, *) {
            Themes.shared.currentUserTheme = window?.traitCollection.userInterfaceStyle.rawValue
        }

        if UserPreferences.ftpKey {
            Core.shared.startFileSharing()
        }

        func showAds() {
            #if !targetEnvironment(macCatalyst)
            DispatchQueue.global(qos: .utility).async {
                sleep(1)
                if !self.openedByFile {
                    FullscreenAd.shared.load()
                }
            }
            #endif
        }

        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { _ in
                showAds()
            }
        } else {
            showAds()
        }

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        print("Path: " + url.path)
        if url.absoluteString.hasPrefix("magnet:") {
            Core.shared.addMagnet(url.absoluteString)
        } else {
            let openInPlace = options[.openInPlace] as? Bool ?? false
            Core.shared.addTorrentFromFile(url, openInPlace: openInPlace)
        }

        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        Core.shared.saveTorrents()
        _ = BackgroundTask.shared.startBackground()
        AppDelegate.backgrounded = true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        } else {
            UIApplication.shared.cancelAllLocalNotifications()
        }
        UIApplication.shared.applicationIconBadgeNumber = 0
        BackgroundTask.shared.stopBackgroundTask()
        TorrentSdk.resumeToApp()
        AppDelegate.backgrounded = false
    }

    func applicationWillTerminate(_ application: UIApplication) {
        Core.shared.saveTorrents(filesStatesOnly: false)
    }

    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        RssFeedProvider.shared.fetchUpdates { updates in
            if updates.keys.count > 0 {
                let unmuted = updates.keys
                    .filter { !$0.muteNotifications.value }

                if unmuted.count > 0 {
                    let text = unmuted
                        .map { updates[$0]! }
                        .reduce([], +)
                        .compactMap { $0.title }
                        .joined(separator: "\n")

                    NotificationHelper.showNotification(title: Localize.get("RssFeedProvider.Notification.Title"),
                                                        body: text,
                                                        hash: "RSS")
                }
                completionHandler(.newData)
            } else {
                completionHandler(.noData)
            }
        }
    }
}
