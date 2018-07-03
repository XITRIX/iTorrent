//
//  Manager.swift
//  iTorrent
//
//  Created by  XITRIX on 14.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

class Manager {
	
	public static var previousTorrentStates : [TorrentStatus] = []
    public static var torrentStates : [TorrentStatus] = []
    public static let rootFolder = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!;
    public static let configFolder = Manager.rootFolder + "/_Config"
	public static let fastResumesFolder = Manager.configFolder+"/.FastResumes"
    public static var managersUpdatedDelegates : [ManagersUpdatedDelegate] = []
    public static var managersStateChangedDelegade : [ManagerStateChangedDelegate] = []
	public static var managerSaves : [String : UserManagerSettings] = [:]
	public static var engineInited : Bool = false
	public static var torrentsRestored : Bool = false
    
    public static func InitManager() {
        DispatchQueue.global(qos: .background).async {
            init_engine(Manager.rootFolder)
			engineInited = true
            restoreAllTorrents()
			
			let down = UserDefaults.standard.value(forKey: UserDefaultsKeys.downloadLimit) as! Int64
			set_download_limit(Int32(down))
			
			let up = UserDefaults.standard.value(forKey: UserDefaultsKeys.uploadLimit) as! Int64
			set_upload_limit(Int32(up))
			
            while(true) {
                mainLoop()
                sleep(1)
            }
        }
        
    }
	
	public static func saveTorrents() {
		let encodedData = NSKeyedArchiver.archivedData(withRootObject: managerSaves)
		do {
			try encodedData.write(to: URL(fileURLWithPath: fastResumesFolder + "/userData.dat"))
		} catch {
			print("Couldn't write file")
		}
		save_fast_resume()
	}
    
    static func restoreAllTorrents() {
        Utils.checkFolderExist(path: configFolder)
		Utils.checkFolderExist(path: fastResumesFolder)
		
		if let loadedStrings = NSKeyedUnarchiver.unarchiveObject(withFile: fastResumesFolder + "/userData.dat") as? [String : UserManagerSettings] {
			print("resumed")
			managerSaves = loadedStrings
		}
		
        let files = try! FileManager.default.contentsOfDirectory(atPath: Manager.configFolder).filter({$0.hasSuffix(".torrent")})
        for file in files {
			if (file == "_temp.torrent") { continue }
            addTorrent(configFolder + "/" + file)
        }
		torrentsRestored = true
    }
	
	static func removeTorrentFile(hash: String) {
		let files = try! FileManager.default.contentsOfDirectory(atPath: Manager.configFolder).filter({$0.hasSuffix(".torrent")})
		for file in files {
			if (hash == String(cString: get_torrent_file_hash(configFolder + "/" + file))) {
				try! FileManager.default.removeItem(atPath: configFolder + "/" + file)
				break
			}
		}
	}
    
    static func mainLoop() {
        let res = getTorrentInfo()
		previousTorrentStates = torrentStates
        torrentStates.removeAll()
        let nameArr = Array(UnsafeBufferPointer(start: res.name, count: Int(res.count)))
        let stateArr = Array(UnsafeBufferPointer(start: res.state, count: Int(res.count)))
        var hashArr = Array(UnsafeBufferPointer(start: res.hash, count: Int(res.count)))
        let creatorArr = Array(UnsafeBufferPointer(start: res.creator, count: Int(res.count)))
        let commentArr = Array(UnsafeBufferPointer(start: res.comment, count: Int(res.count)))
        for i in 0 ..< Int(res.count) {
            let status = TorrentStatus()
            
            status.state = String(validatingUTF8: stateArr[Int(i)]!) ?? "ERROR"
            status.title = status.state == Utils.torrentStates.Metadata.rawValue ? "Obtaining Metadata" : String(validatingUTF8: nameArr[Int(i)]!) ?? "ERROR"
            status.hash = String(validatingUTF8: hashArr[Int(i)]!) ?? "ERROR"
            status.creator = String(validatingUTF8: creatorArr[Int(i)]!) ?? "ERROR"
            status.comment = String(validatingUTF8: commentArr[Int(i)]!) ?? "ERROR"
            status.progress = res.progress[i]
            status.totalWanted = res.total_wanted[i]
            status.totalWantedDone = res.total_wanted_done[i]
            status.downloadRate = Int(res.download_rate[i])
            status.uploadRate = Int(res.upload_rate[i])
            status.totalDownload = res.total_download[i]
            status.totalUpload = res.total_upload[i]
            status.numSeeds = Int(res.num_seeds[i])
            status.numPeers = Int(res.num_peers[i])
            status.totalSize = res.total_size[i]
            status.totalDone = res.total_done[i]
            status.creationDate = Date(timeIntervalSince1970: TimeInterval(res.creation_date[i]))
            status.isPaused = res.is_paused[i] == 1
            status.isFinished = res.is_finished[i] == 1
            status.isSeed = res.is_seed[i] == 1
			status.hasMetadata = res.has_metadata[i] == 1
			
			if (managerSaves[status.hash] == nil) {
				managerSaves[status.hash] = UserManagerSettings()
			}
			status.addedDate = managerSaves[status.hash]?.addedDate
			status.seedMode = (managerSaves[status.hash]?.seedMode)!
			status.seedLimit = (managerSaves[status.hash]?.seedLimit)!
			
            status.displayState = getDisplayState(manager: status)
			//print(status.displayState)
			
            Manager.torrentStates.append(status)
			stateCorrector(manager: status)
        }
        
        DispatchQueue.main.async {
            for i in Manager.managersUpdatedDelegates {
                i.managerUpdated();
            }
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
                    let controller = ThemedUIAlertController(title: "Error", message: "Finish the previous torrent adding before start the new one.", preferredStyle: .alert)
                    let close = UIAlertAction(title: "Close", style: .cancel)
                    controller.addAction(close)
                    nav.present(controller, animated: true)
                    
                    return
                }
            }
        }
		
		DispatchQueue.global(qos: .background).async {
			while (!torrentsRestored) { sleep(1) }
			DispatchQueue.main.async {
				let dest = Manager.configFolder+"/_temp.torrent"
				print(filePath.startAccessingSecurityScopedResource())
				do {
					if (FileManager.default.fileExists(atPath: dest)) {
						try FileManager.default.removeItem(atPath: dest)
					}
					print(FileManager.default.fileExists(atPath: filePath.path))
					try FileManager.default.copyItem(at: filePath, to: URL(fileURLWithPath: dest))
				} catch {
					let controller = ThemedUIAlertController(title: "Error on torrent opening", message: error.localizedDescription, preferredStyle: .alert)
					let close = UIAlertAction(title: "Close", style: .cancel)
					controller.addAction(close)
					UIApplication.shared.keyWindow?.rootViewController?.present(controller, animated: true)
					
					return
				}
				filePath.stopAccessingSecurityScopedResource()
				
				let hash = String(validatingUTF8: get_torrent_file_hash(dest))!
				if (hash == "-1") {
					let controller = ThemedUIAlertController(title: "Error on torrent reading", message: "Torrent file opening error has been occured", preferredStyle: .alert)
					let close = UIAlertAction(title: "Close", style: .cancel)
					controller.addAction(close)
					UIApplication.shared.keyWindow?.rootViewController?.present(controller, animated: true)
					return
				} else if (torrentStates.contains(where: {$0.hash == hash})) {
					let controller = ThemedUIAlertController(title: "This torrent already exists", message: "Torrent with hash: \"" + hash + "\" already exists in download queue", preferredStyle: .alert)
					let close = UIAlertAction(title: "Close", style: .cancel)
					controller.addAction(close)
					UIApplication.shared.keyWindow?.rootViewController?.present(controller, animated: true)
					return
				}
				do {
					let controller = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "AddTorrent")
					((controller as! UINavigationController).topViewController as! AddTorrentController).path = dest
					UIApplication.shared.keyWindow?.rootViewController?.present(controller, animated: true)
				}
			}
		}
	}
    
    static func addTorrent(_ filePath: String) {
		if let hash = String(validatingUTF8: add_torrent(filePath)) {
			if hash != "-1",
				managerSaves[hash] == nil {
				print(hash)
				managerSaves[hash] = UserManagerSettings()
			} else if hash == "-1" {
				do {
					try FileManager.default.removeItem(atPath: filePath)
				} catch { print(error.localizedDescription) }
			}
		}
        mainLoop()
	}
    
    static func addMagnet(_ magnetLink: String) {
		if magnetLink.starts(with: "magnet:") {
			DispatchQueue.global(qos: .background).async {
				while (!torrentsRestored) { sleep(1) }
				DispatchQueue.main.async {
					let hash = String(validatingUTF8: get_magnet_hash(magnetLink))
					if (Manager.torrentStates.contains(where: {$0.hash == hash})) {
						let alert = ThemedUIAlertController(title: "This torrent already exists", message: "Torrent with hash: \"" + hash! + "\" already exists in download queue", preferredStyle: .alert)
						let close = UIAlertAction(title: "Close", style: .cancel)
						alert.addAction(close)
						UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true)
					} else if let hash = String(validatingUTF8: add_magnet(magnetLink)) {
						print(hash)
						managerSaves[hash] = UserManagerSettings()
						mainLoop()
					} else {
						let controller = ThemedUIAlertController(title: "Error", message: "Wrong magnet link, check it and try again!", preferredStyle: .alert)
						let close = UIAlertAction(title: "Close", style: .cancel)
						controller.addAction(close)
						UIApplication.shared.keyWindow?.rootViewController?.present(controller, animated: true)
					}
				}
			}
		}
    }
	
	static func isManagerExists(hash: String) -> Bool {
		return torrentStates.contains(where: {$0.hash == hash})
	}
    
    static func getDisplayState(manager: TorrentStatus) -> String {
        if (manager.state == Utils.torrentStates.Finished.rawValue && !manager.isPaused && (managerSaves[manager.hash]?.seedMode)!) {
            return Utils.torrentStates.Seeding.rawValue
        }
		if (manager.state == Utils.torrentStates.Seeding.rawValue && manager.isPaused) {
            return Utils.torrentStates.Finished.rawValue
        }
		if (manager.state == Utils.torrentStates.Downloading.rawValue && !manager.isFinished && manager.isPaused) {
			return Utils.torrentStates.Paused.rawValue
		}
        return manager.state
    }
	
	static func stateCorrector(manager: TorrentStatus) {
		if (manager.displayState == Utils.torrentStates.Seeding.rawValue &&
			!(managerSaves[manager.hash]?.seedMode)!) {
			stop_torrent(manager.hash)
		} else if ((manager.state == Utils.torrentStates.Seeding.rawValue || manager.state == Utils.torrentStates.Downloading.rawValue) &&
			manager.isFinished &&
			!manager.isPaused &&
			!(managerSaves[manager.hash]?.seedMode)!) {
			stop_torrent(manager.hash)
		} else if (manager.state == Utils.torrentStates.Seeding.rawValue &&
			!manager.isPaused &&
			!(managerSaves[manager.hash]?.seedMode)!) {
			stop_torrent(manager.hash)
		} else if (manager.displayState == Utils.torrentStates.Seeding.rawValue &&
			!manager.isPaused &&
			(managerSaves[manager.hash]?.seedMode)! &&
			manager.totalUpload >= (managerSaves[manager.hash]?.seedLimit)! &&
			(managerSaves[manager.hash]?.seedLimit)! != 0) {
			managerSaves[manager.hash]?.seedMode = false
			stop_torrent(manager.hash)
		} else if (manager.state == Utils.torrentStates.Hashing.rawValue && manager.isPaused) {
			start_torrent(manager.hash)
		}
	}
	
	static func stateChanges() {
		for t in torrentStates {
			if let old = previousTorrentStates.filter({ $0.hash == t.hash }).first {
				if (old.displayState != t.displayState) {
					DispatchQueue.main.async {
						for m in managersStateChangedDelegade {
							m.managerStateChanged(manager: t, oldState: old.displayState, newState: t.displayState)
						}
						managersStateChanged(manager: t, oldState: old.displayState, newState: t.displayState)
					}
				}
			} else {
				DispatchQueue.main.async {
					for m in managersStateChangedDelegade {
						m.managerStateChanged(manager: t, oldState: "NONE", newState: t.displayState)
					}
					managersStateChanged(manager: t, oldState: "NONE", newState: t.displayState)
				}
			}
		}
	}
	
	static func managersStateChanged(manager: TorrentStatus, oldState: String, newState: String) {
		if (oldState == Utils.torrentStates.Metadata.rawValue) {
			save_magnet_to_file(manager.hash)
		}
        if UserDefaults.standard.bool(forKey: UserDefaultsKeys.notificationsKey) &&
			(oldState == Utils.torrentStates.Downloading.rawValue && (newState == Utils.torrentStates.Finished.rawValue || newState == Utils.torrentStates.Seeding.rawValue)) {
			if #available(iOS 10.0, *) {
				let content = UNMutableNotificationContent()
				
				content.title = "Download finished"
				content.body = manager.title + " finished downloading"
				content.sound = UNNotificationSound.default()
				
				let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
				let identifier = manager.hash;
				let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
				
				UNUserNotificationCenter.current().add(request)
            } else {
                let notification = UILocalNotification()
				
                notification.fireDate = NSDate(timeIntervalSinceNow: 1) as Date
                notification.alertTitle = "Download finished"
                notification.alertBody = manager.title + " finished downloading"
                notification.soundName = UILocalNotificationDefaultSoundName
				
                UIApplication.shared.scheduleLocalNotification(notification)
            }
			
			if (UserDefaults.standard.bool(forKey: UserDefaultsKeys.badgeKey)) {
				UIApplication.shared.applicationIconBadgeNumber += 1
			}
			
			BackgroundTask.checkToStopBackground()
		}
		if UserDefaults.standard.bool(forKey: UserDefaultsKeys.notificationsSeedKey) &&
			(oldState == Utils.torrentStates.Seeding.rawValue && (newState == Utils.torrentStates.Finished.rawValue)) {
			if #available(iOS 10.0, *) {
				let content = UNMutableNotificationContent()
				
				content.title = "Seeding finished"
				content.body = manager.title + " finished seeding"
				content.sound = UNNotificationSound.default()
				
				let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
				let identifier = manager.hash;
				let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
				
				UNUserNotificationCenter.current().add(request)
			} else {
				let notification = UILocalNotification()
				
				notification.fireDate = NSDate(timeIntervalSinceNow: 1) as Date
				notification.alertTitle = "Seeding finished"
				notification.alertBody = manager.title + " finished seeding"
				notification.soundName = UILocalNotificationDefaultSoundName
				
				UIApplication.shared.scheduleLocalNotification(notification)
			}
			
			if (UserDefaults.standard.bool(forKey: UserDefaultsKeys.badgeKey)) {
				UIApplication.shared.applicationIconBadgeNumber += 1
			}
			
			BackgroundTask.checkToStopBackground()
		}
	}
    
    static func getManagerByHash(hash: String) -> TorrentStatus? {
		let localStates = torrentStates
        return localStates.filter({$0.hash == hash}).first
    }
	
	static func startFTP(){
		DispatchQueue.global(qos: .background).async {
			ftp_start(21, rootFolder)
		}
	}
	
	static func stopFTP(){
		DispatchQueue.global(qos: .background).async {
			ftp_stop()
		}
	}
}
