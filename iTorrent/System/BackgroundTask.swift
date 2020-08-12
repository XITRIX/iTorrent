//
//  BackgroundTask.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 19.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import ITorrentFramework
import AVFoundation

class BackgroundTask {
    public static let shared = BackgroundTask()
    
    var player: AVAudioPlayer?
    var timer = Timer()
    var backgrounding = false

    func startBackgroundTask() {
        if !backgrounding {
            NotificationCenter.default.addObserver(self, selector: #selector(interruptedAudio), name: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance())
            backgrounding = true
            playAudio()
        }
    }

    func stopBackgroundTask() {
        if backgrounding {
            NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
            backgrounding = false
            player?.stop()
        }
    }
    
    @objc fileprivate func interruptedAudio(_ notification: Notification) {
        if notification.name == AVAudioSession.interruptionNotification,
            let info = notification.userInfo {
            var intValue = 0
            let key = info[AVAudioSessionInterruptionTypeKey] as AnyObject
            key.getValue(&intValue)
            if intValue == 1 { playAudio() }
        }
    }

    fileprivate func playAudio() {
        do {
            let bundle = Bundle.main.path(forResource: "3", ofType: "wav")
            let alertSound = URL(fileURLWithPath: bundle!)
            try AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            try self.player = AVAudioPlayer(contentsOf: alertSound)
            
            self.player?.numberOfLoops = -1
            self.player?.volume = 0.01
            self.player?.prepareToPlay()
            self.player?.play()
        } catch {
            print(error)
        }
    }

    func startBackground() -> Bool {
        if UserPreferences.background {
            if Core.shared.torrents.values.contains(where: { (status) -> Bool in
                BackgroundTask.getBackgroundConditions(status)
            }) {
                startBackgroundTask()
                return true
            }
        }
        return false
    }

    func checkToStopBackground() {
        if !Core.shared.torrents.values.contains(where: { BackgroundTask.getBackgroundConditions($0) }) {
            if backgrounding {
                Core.shared.saveTorrents()
                stopBackgroundTask()
            }
        }
    }

    static func getBackgroundConditions(_ status: TorrentModel) -> Bool {
        // state conditions
        (status.displayState == .downloading ||
            status.displayState == .metadata ||
            status.displayState == .hashing ||
            (status.displayState == .seeding &&
                UserPreferences.backgroundSeedKey &&
                status.seedMode) ||
            (UserPreferences.ftpKey &&
                UserPreferences.ftpBackgroundKey)) &&
            // zero speed limit conditions
            ((UserPreferences.zeroSpeedLimit > 0 &&
                    Core.shared.torrentsUserData[status.hash]?.zeroSpeedTimeCounter ?? 0 < UserPreferences.zeroSpeedLimit) ||
                UserPreferences.zeroSpeedLimit == 0)
    }
}
