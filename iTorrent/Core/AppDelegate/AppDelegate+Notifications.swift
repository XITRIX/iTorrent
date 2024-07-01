//
//  AppDelegate+Notifications.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 03/04/2024.
//

import LibTorrent
import UIKit
import UserNotifications
import MvvmFoundation

extension AppDelegate: UNUserNotificationCenterDelegate {
    func registerPushNotifications(_ application: UIApplication) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            print("Granted: " + String(granted))
        }
        center.removeAllDeliveredNotifications()
        center.delegate = self
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.list, .banner, .badge, .sound]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        guard let hash = response.notification.request.content.userInfo["hash"] as? String,
              let torrentHandle = TorrentService.shared.torrents.values.first(where: { $0.snapshot.infoHashes.best.hex == hash })
        else { return }

        Self.showTorrentDetailScreen(with: torrentHandle)
    }
}

extension AppDelegate {
    static func showTorrentDetailScreen(with torrentHandle: TorrentHandle) {
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
              let window = scene.keyWindow,
              let viewController = window.rootViewController
        else { return }

        // If same screen already presented, do not show another one
        if let svc = viewController as? UISplitViewController,
           let mvvmVC = svc.detailNavigationController?.topViewController as? any MvvmViewControllerProtocol,
           let viewModel = mvvmVC.viewModel as? TorrentDetailsViewModel,
           viewModel.infoHashes.best.hex == torrentHandle.snapshot.infoHashes.best.hex
        { return }

        let vc = TorrentDetailsViewModel(with: torrentHandle).resolveVC()
        viewController.navigate(to: vc, by: .detail(asRoot: true))
    }
}
