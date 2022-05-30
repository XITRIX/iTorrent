//
//  BackgroundTask.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 19.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import AVFoundation

class BackgroundTask {
    public static let shared = BackgroundTask()

    private var player: AVAudioPlayer?
    private var timer = Timer()
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

    @objc private func interruptedAudio(_ notification: Notification) {
        if notification.name == AVAudioSession.interruptionNotification,
            let info = notification.userInfo {
            var intValue = 0
            let key = info[AVAudioSessionInterruptionTypeKey] as AnyObject
            key.getValue(&intValue)
            if intValue == 1 { playAudio() }
        }
    }

    private func playAudio() {
        do {
            let bundle = Bundle.main.path(forResource: "empty", ofType: "wav")
            let alertSound = URL(fileURLWithPath: bundle!)
            try AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            try player = AVAudioPlayer(contentsOf: alertSound)

            player?.numberOfLoops = -1
            player?.volume = 0.01
            player?.prepareToPlay()
            player?.play()
        } catch {
            print(error)
        }
    }
}
