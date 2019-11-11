//
//  Manager.swift
//  iTorrent
//
//  Created by  XITRIX on 14.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import UIKit
import UserNotifications
import GCDWebServer

class Manager {
    public static var previousTorrentStates: [TorrentStatus] = []
    public static var torrentStates: [TorrentStatus] = []
    public static let rootFolder = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
    public static let configFolder = Manager.rootFolder + "/_Config"
    public static let fastResumesFolder = Manager.configFolder + "/.FastResumes"
    public static var managerSaves: [String: UserManagerSettings] = [:]
    public static var engineInited: Bool = false
    public static var torrentsRestored: Bool = false

    public static var webUploadServer = GCDWebUploader(uploadDirectory: Manager.rootFolder)
    public static var webDAVServer = GCDWebDAVServer(uploadDirectory: Manager.rootFolder)

    public static func initManager() {
        DispatchQueue.global(qos: .background).async {
            init_engine(Manager.rootFolder, Manager.configFolder)
            engineInited = true
            restoreAllTorrents()

            let down = UserPreferences.downloadLimit.value
            set_download_limit(Int32(down))

            let up = UserPreferences.uploadLimit.value
            set_upload_limit(Int32(up))

            while (true) {
                mainLoop()
                sleep(1)
            }
        }

    }

    public static func saveTorrents(filesStatesOnly: Bool = false) {
        let encodedData = NSKeyedArchiver.archivedData(withRootObject: managerSaves)
        do {
            try encodedData.write(to: URL(fileURLWithPath: fastResumesFolder + "/userData.dat"))
        } catch {
            print("Couldn't write file")
        }
        if (!filesStatesOnly) {
            save_fast_resume()
        }
    }

    static func restoreAllTorrents() {
        Utils.checkFolderExist(path: configFolder)
        Utils.checkFolderExist(path: fastResumesFolder)

        if let loadedStrings = NSKeyedUnarchiver.unarchiveObject(withFile: fastResumesFolder + "/userData.dat") as? [String: UserManagerSettings] {
            print("resumed")
            managerSaves = loadedStrings
        }

        if let files = try? FileManager.default.contentsOfDirectory(atPath: Manager.configFolder).filter({ $0.hasSuffix(".torrent") }) {
            for file in files {
                if (file == "_temp.torrent") {
                    continue
                }
                addTorrent(configFolder + "/" + file)
            }
        } else {
            //TODO: Error handler
        }
        torrentsRestored = true
    }

    static func removeTorrentFile(hash: String) {
        let files = try? FileManager.default.contentsOfDirectory(atPath: Manager.configFolder).filter({ $0.hasSuffix(".torrent") })
        for file in files ?? [] {
            if (hash == String(cString: get_torrent_file_hash(configFolder + "/" + file))) {
                try? FileManager.default.removeItem(atPath: configFolder + "/" + file)
                break
            }
        }
    }

    static func mainLoop() {
        let res = getTorrentInfo()
        previousTorrentStates = torrentStates
        torrentStates.removeAll()
        let torrents = Array(UnsafeBufferPointer(start: res.torrents, count: Int(res.count)))
        for iter in 0..<Int(res.count) {
            let status = TorrentStatus(torrents[iter])
            Manager.torrentStates.append(status)
            status.stateCorrector()
        }

        // check torrents speed to stop if == 0
        for status in Manager.torrentStates {
            status.checkSpeed()
        }

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .torrentsUpdated, object: nil)
        }

        stateChanges()
    }

    static func addTorrentFromFile(_ filePath: URL) {
        if var topController = UIApplication.shared.keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            if var nav = (topController as? UINavigationController)?.topViewController {
                while let presentedViewController = nav.presentedViewController {
                    nav = presentedViewController
                }
                if nav is AddTorrentController {
                    let controller = ThemedUIAlertController(title: NSLocalizedString("Error", comment: ""),
                        message: Localize.get("Finish the previous torrent adding before start the new one."),
                        preferredStyle: .alert)
                    let close = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .cancel)
                    controller.addAction(close)
                    nav.present(controller, animated: true)

                    return
                }
            }
        }

        DispatchQueue.global(qos: .background).async {
            while (!torrentsRestored) {
                sleep(1)
            }
            DispatchQueue.main.async {
                let dest = Manager.configFolder + "/_temp.torrent"
                print(filePath.startAccessingSecurityScopedResource())
                do {
                    if (FileManager.default.fileExists(atPath: dest)) {
                        try FileManager.default.removeItem(atPath: dest)
                    }
                    print(FileManager.default.fileExists(atPath: filePath.path))
                    try FileManager.default.copyItem(at: filePath, to: URL(fileURLWithPath: dest))
                } catch {
                    let controller = ThemedUIAlertController(title: NSLocalizedString("Error on torrent opening", comment: ""), message: error.localizedDescription, preferredStyle: .alert)
                    let close = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .cancel)
                    controller.addAction(close)
                    UIApplication.shared.keyWindow?.rootViewController?.present(controller, animated: true)

                    return
                }
                filePath.stopAccessingSecurityScopedResource()

                let hash = String(validatingUTF8: get_torrent_file_hash(dest))!
                if (hash == "-1") {
                    let controller = ThemedUIAlertController(title: Localize.get("Error on torrent reading"),
                        message: Localize.get("Torrent file opening error has been occured"),
                        preferredStyle: .alert)
                    let close = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .cancel)
                    controller.addAction(close)
                    UIApplication.shared.keyWindow?.rootViewController?.present(controller, animated: true)
                    return
                } else if (torrentStates.contains(where: { $0.hash == hash })) {
                    let controller = ThemedUIAlertController(title: Localize.get("This torrent already exists"),
                        message: "\(Localize.get("Torrent with hash:")) \"\(hash)\" \(Localize.get("already exists in download queue"))",
                        preferredStyle: .alert)
                    let close = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .cancel)
                    controller.addAction(close)
                    UIApplication.shared.keyWindow?.rootViewController?.present(controller, animated: true)
                    return
                }
                do {
                    let controller = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "AddTorrent")
                    ((controller as? UINavigationController)?.topViewController as? AddTorrentController)?.path = dest
                    UIApplication.shared.keyWindow?.rootViewController?.present(controller, animated: true)
                }
            }
        }
    }

    static func addTorrent(_ filePath: String) {
        if let hash = String(validatingUTF8: add_torrent(filePath)) {
            if hash != "-1" {
                if managerSaves[hash] == nil {
                    print(hash)
                    managerSaves[hash] = UserManagerSettings()
                }
            } else {
                do {
                    try FileManager.default.removeItem(atPath: filePath)
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
        mainLoop()
    }

    static func addMagnet(_ magnetLink: String) {
        if magnetLink.starts(with: "magnet:") {
            DispatchQueue.global(qos: .background).async {
                while (!torrentsRestored) {
                    sleep(1)
                }
                DispatchQueue.main.async {
                    let hash = String(validatingUTF8: get_magnet_hash(magnetLink))
                    if (Manager.torrentStates.contains(where: { $0.hash == hash })) {
                        let alert = ThemedUIAlertController(title: Localize.get("This torrent already exists"),
                            message: "\(Localize.get("Torrent with hash:")) \"\(hash ?? "UNKNOWN")\" \(Localize.get("already exists in download queue"))",
                            preferredStyle: .alert)
                        let close = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .cancel)
                        alert.addAction(close)
                        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true)
                    } else if let hash = String(validatingUTF8: add_magnet(magnetLink)) {
                        print(hash)
                        managerSaves[hash] = UserManagerSettings()
                        mainLoop()
                    } else {
                        let controller = ThemedUIAlertController(title: Localize.get("Error"),
                            message: Localize.get("Wrong magnet link, check it and try again!"),
                            preferredStyle: .alert)
                        let close = UIAlertAction(title: NSLocalizedString(NSLocalizedString("Close", comment: ""), comment: ""), style: .cancel)
                        controller.addAction(close)
                        UIApplication.shared.keyWindow?.rootViewController?.present(controller, animated: true)
                    }
                }
            }
        }
    }

    static func isManagerExists(hash: String) -> Bool {
        torrentStates.contains(where: { $0.hash == hash })
    }

    static func stateChanges() {
        for torrentState in torrentStates {
            if let old = previousTorrentStates.filter({ $0.hash == torrentState.hash }).first {
                if (old.displayState != torrentState.displayState) {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .torrentsStateChanged,
                            object: nil,
                            userInfo: ["data": (manager: torrentState, oldState: old.displayState, newState: torrentState.displayState)])
                        managersStateChanged(manager: torrentState,
                            oldState: old.displayState,
                            newState: torrentState.displayState)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .torrentsStateChanged,
                        object: nil,
                        userInfo: ["data": (manager: torrentState, oldState: "NONE", newState: torrentState.displayState)])
                    managersStateChanged(manager: torrentState, oldState: "NONE", newState: torrentState.displayState)
                }
            }
        }
    }

    static func managersStateChanged(manager: TorrentStatus, oldState: String, newState: String) {
        if (oldState == Utils.TorrentStates.metadata.rawValue) {
            save_magnet_to_file(manager.hash)
        }
        if UserPreferences.notificationsKey.value &&
               (oldState == Utils.TorrentStates.downloading.rawValue && (newState == Utils.TorrentStates.finished.rawValue || newState == Utils.TorrentStates.seeding.rawValue)) {
            if #available(iOS 10.0, *) {
                let content = UNMutableNotificationContent()

                content.title = NSLocalizedString("Download finished", comment: "")
                content.body = manager.title + NSLocalizedString(" finished downloading", comment: "")
                content.sound = UNNotificationSound.default
                content.userInfo = ["hash": manager.hash]

                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                let identifier = manager.hash;
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

                UNUserNotificationCenter.current().add(request)
            } else {
                let notification = UILocalNotification()

                notification.fireDate = NSDate(timeIntervalSinceNow: 1) as Date
                notification.alertTitle = NSLocalizedString("Download finished", comment: "")
                notification.alertBody = manager.title + NSLocalizedString(" finished downloading", comment: "")
                notification.soundName = UILocalNotificationDefaultSoundName
                notification.userInfo = ["hash": manager.hash]

                UIApplication.shared.scheduleLocalNotification(notification)
            }

            if (UserPreferences.badgeKey.value && AppDelegate.backgrounded) {
                UIApplication.shared.applicationIconBadgeNumber += 1
            }

            BackgroundTask.checkToStopBackground()
        }
        if UserPreferences.notificationsSeedKey.value &&
               (oldState == Utils.TorrentStates.seeding.rawValue && (newState == Utils.TorrentStates.finished.rawValue)) {
            if #available(iOS 10.0, *) {
                let content = UNMutableNotificationContent()

                content.title = NSLocalizedString("Seeding finished", comment: "")
                content.body = manager.title + NSLocalizedString(" finished seeding", comment: "")
                content.sound = UNNotificationSound.default
                content.userInfo = ["hash": manager.hash]

                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                let identifier = manager.hash;
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

                UNUserNotificationCenter.current().add(request)
            } else {
                let notification = UILocalNotification()

                notification.fireDate = NSDate(timeIntervalSinceNow: 1) as Date
                notification.alertTitle = NSLocalizedString("Seeding finished", comment: "")
                notification.alertBody = manager.title + NSLocalizedString(" finished seeding", comment: "")
                notification.soundName = UILocalNotificationDefaultSoundName
                notification.userInfo = ["hash": manager.hash]

                UIApplication.shared.scheduleLocalNotification(notification)
            }

            if (UserPreferences.badgeKey.value && AppDelegate.backgrounded) {
                UIApplication.shared.applicationIconBadgeNumber += 1
            }

            BackgroundTask.checkToStopBackground()
        }
    }

    static func getManagerByHash(hash: String) -> TorrentStatus? {
        let localStates = torrentStates
        let filter = localStates.filter({ $0.hash == hash })
        return filter.count > 0 ? filter.first : nil
    }

    static func startFileSharing() {
        var options = [String : Any]()
        
        if (!UserPreferences.webDavUsername.value.isEmpty) {
            options[GCDWebServerOption_AuthenticationAccounts] = [UserPreferences.webDavUsername.value: UserPreferences.webDavPassword.value]
            options[GCDWebServerOption_AuthenticationMethod] = GCDWebServerAuthenticationMethod_DigestAccess
        }
        
        if UserPreferences.webDavWebServerEnabled.value {
            options[GCDWebServerOption_Port] = 80
            if !webUploadServer.isRunning {
                if (try? webUploadServer.start(options: options)) == nil {
                    repeat {
                        options[GCDWebServerOption_Port] = Int.random(in: 49152 ..< 65535)
                    } while (try? webUploadServer.start(options: options)) == nil
                }
            }
        }
        
        if UserPreferences.webDavWebDavServerEnabled.value {
            options[GCDWebServerOption_Port] = UserPreferences.webDavPort.value
            if !webDAVServer.isRunning {
                try? webDAVServer.start(options: options)
            }
        }
    }

    static func stopFileSharing() {
        if (webUploadServer.isRunning) {
            webUploadServer.stop()
        }
        if (webDAVServer.isRunning) {
            webDAVServer.stop()
        }
    }
}
