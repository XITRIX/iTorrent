//
//  BackgroundTask.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 19.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import AVFoundation

class BackgroundTask {
	
	static var player = AVAudioPlayer()
	static var timer = Timer()
	static var backgrounding = false
	
	static func startBackgroundTask() {
		if (!backgrounding) {
			NotificationCenter.default.addObserver(self, selector: #selector(interuptedAudio), name: NSNotification.Name.AVAudioSessionInterruption, object: AVAudioSession.sharedInstance())
			BackgroundTask.playAudio()
			backgrounding = true
		}
	}
	
	static func stopBackgroundTask() {
		if (backgrounding) {
			NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVAudioSessionInterruption, object: nil)
			player.stop()
			backgrounding = false
		}
	}
	
	@objc fileprivate func interuptedAudio(_ notification: Notification) {
		if notification.name == NSNotification.Name.AVAudioSessionInterruption && notification.userInfo != nil {
			var info = notification.userInfo!
			var intValue = 0
			(info[AVAudioSessionInterruptionTypeKey]! as AnyObject).getValue(&intValue)
			if intValue == 1 { BackgroundTask.playAudio() }
		}
	}
	
	static fileprivate func playAudio() {
		do {
			let bundle = Bundle.main.path(forResource: "3", ofType: "wav")
			let alertSound = URL(fileURLWithPath: bundle!)
			try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with:AVAudioSessionCategoryOptions.mixWithOthers)
			try AVAudioSession.sharedInstance().setActive(true)
			try BackgroundTask.player = AVAudioPlayer(contentsOf: alertSound)
			BackgroundTask.player.numberOfLoops = -1
			BackgroundTask.player.volume = 0.01
			BackgroundTask.player.prepareToPlay()
			BackgroundTask.player.play()
		} catch { print(error) }
	}
	
	static func startBackground() -> Bool {
		if (UserDefaults.standard.bool(forKey: UserDefaultsKeys.backgroundKey)) {
			if (Manager.torrentStates.contains(where: { (status) -> Bool in
				return getBackgroundConditions(status)
			})) {
				startBackgroundTask()
				return true
			}
		}
		return false
	}
	
	static func checkToStopBackground() {
		if (!Manager.torrentStates.contains(where: { (status) -> Bool in
			return getBackgroundConditions(status)
		})) {
			if (backgrounding) {
				Manager.saveTorrents()
				stopBackgroundTask()
			}
		}
	}
	
	static func getBackgroundConditions(_ status: TorrentStatus) -> Bool {
		return status.displayState == Utils.torrentStates.Downloading.rawValue ||
			status.displayState == Utils.torrentStates.Metadata.rawValue ||
			status.displayState == Utils.torrentStates.Hashing.rawValue ||
			(status.displayState == Utils.torrentStates.Seeding.rawValue &&
				UserDefaults.standard.bool(forKey: UserDefaultsKeys.backgroundSeedKey) &&
				status.seedMode) ||
			(UserDefaults.standard.bool(forKey: UserDefaultsKeys.ftpKey) &&
			UserDefaults.standard.bool(forKey: UserDefaultsKeys.ftpBackgroundKey))
	}
}
