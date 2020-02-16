//
//  NutificationSender.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 16.02.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit
import UserNotifications

class NotificationHelper {
    public static func showNotification(title: String, body: String, hash: String) {
        if #available(iOS 10.0, *) {
            let content = UNMutableNotificationContent()

            content.title = title
            content.body = body
            content.sound = UNNotificationSound.default
            content.userInfo = ["hash": hash]

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let identifier = hash;
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request)
        } else {
            let notification = UILocalNotification()

            notification.fireDate = NSDate(timeIntervalSinceNow: 1) as Date
            notification.alertTitle = title
            notification.alertBody = body
            notification.soundName = UILocalNotificationDefaultSoundName
            notification.userInfo = ["hash": hash]

            UIApplication.shared.scheduleLocalNotification(notification)
        }
    }
}
