//
//  BackgroundTask.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 19.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import AVFoundation

class BackgroundTask {
    static let zeroSpeedLimit = 60

    static var player: AVAudioPlayer?
    static var timer = Timer()
    static var backgrounding = false


    static func startBackgroundTask() {
        if (!backgrounding) {
            backgrounding = true
            BackgroundTask.playAudio()
        }
    }

    static func stopBackgroundTask() {
        if (backgrounding) {
            backgrounding = false
            player?.stop()
        }
    }

    static fileprivate func playAudio() {
        do {
            let bundle = Bundle.main.path(forResource: "3", ofType: "wav")
            let alertSound = URL(fileURLWithPath: bundle!)
            try AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            BackgroundTask.player = try AVAudioPlayer(contentsOf: alertSound)
            BackgroundTask.player?.numberOfLoops = -1
            BackgroundTask.player?.volume = 0.01
            BackgroundTask.player?.prepareToPlay()
            BackgroundTask.player?.play()
        } catch {
            print(error)
        }
    }

    static func startBackground() -> Bool {
        if (UserPreferences.background.value) {
            if (Manager.torrentStates.contains(where: { (status) -> Bool in
                getBackgroundConditions(status)
            })) {
                startBackgroundTask()
                return true
            }
        }
        return false
    }

    static func checkToStopBackground() {
        if (!Manager.torrentStates.contains(where: { getBackgroundConditions($0) })) {
            if (backgrounding) {
                Manager.saveTorrents()
                stopBackgroundTask()
            }
        }
    }

    static func getBackgroundConditions(_ status: TorrentStatus) -> Bool {
        (status.displayState == Utils.TorrentStates.downloading.rawValue ||
            status.displayState == Utils.TorrentStates.metadata.rawValue ||
            status.displayState == Utils.TorrentStates.hashing.rawValue ||
            (status.displayState == Utils.TorrentStates.seeding.rawValue &&
                UserPreferences.backgroundSeedKey.value &&
                status.seedMode) ||
            (UserPreferences.ftpKey.value &&
                UserPreferences.ftpBackgroundKey.value)) &&
            Manager.managerSaves[status.hash]?.zeroSpeedTimeCounter ?? 0 < BackgroundTask.zeroSpeedLimit
    }
}
