//
//  AppDelegate+BackgroundRefresh.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 11.04.2024.
//

import BackgroundTasks
import UIKit

extension AppDelegate {
    func registerBackgroundRefresh() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.xitrix.itorrent.refresh",
            using: nil
        ) { task in
            self.handleAppRefresh(task)
        }

        scheduleBackgroundRssFetch()
    }
}

private extension AppDelegate {
    func scheduleBackgroundRssFetch() {
        let rssFetchTask = BGAppRefreshTaskRequest(identifier: "com.xitrix.itorrent.refresh")
        rssFetchTask.earliestBeginDate = nil
        do {
            try BGTaskScheduler.shared.submit(rssFetchTask)
        } catch {
            print("Unable to submit task: \(error.localizedDescription)")
        }
    }

    func handleAppRefresh(_ task: BGTask) {
        let updateTask = Task {
            do {
                var news = try await RssFeedProvider(fetchUpdatesOnInit: false).fetchUpdates()
                news = news.filter { !$0.key.muteNotifications && !$0.value.isEmpty }
                guard !news.isEmpty else { return task.setTaskCompleted(success: true) }

                let message = news
                    .map { $0.value }
                    .reduce([], +)
                    .compactMap { $0.title }
                    .joined(separator: "\n")

                rssUpdateNotification(with: message)
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
                scheduleBackgroundRssFetch()
            }
        }

        task.expirationHandler = {
            updateTask.cancel()
            task.setTaskCompleted(success: false)
        }
    }
}

private extension AppDelegate {
    func rssUpdateNotification(with message: String) {
        let content = UNMutableNotificationContent()

        content.title = %"notification.rss.title"
        content.body = message
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "rss", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
}
