//
//  AudioBackgroundService.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 05/04/2024.
//

import AVFoundation
import UIKit

class AudioBackgroundService {
    private var player: AVAudioPlayer?
    private var backgroundTask: UIBackgroundTaskIdentifier?
}

extension AudioBackgroundService: BackgroundServiceProtocol {
    var isRunning: Bool {
        player?.isPlaying ?? false
    }
    
    func start() -> Bool {
        guard !isRunning else { return true }
        guard playAudio() else { return false }
        startBackgroundTask()
        NotificationCenter.default.addObserver(self, selector: #selector(interruptedAudio), name: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance())
        return true
    }

    func stop() {
        stopBackgroundTask()
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
        player?.stop()
    }
    
    func prepare() async -> Bool { true }
}

private extension AudioBackgroundService {
    @objc func interruptedAudio(_ notification: Notification) {
        if notification.name == AVAudioSession.interruptionNotification,
           let info = notification.userInfo
        {
            var intValue = 0
            let key = info[AVAudioSessionInterruptionTypeKey] as AnyObject
            key.getValue(&intValue)
            if intValue == 1 {
                if !playAudio() {
                    stop()
                }
            }
        }
    }

    @discardableResult
    func playAudio() -> Bool {
        do {
//            let bundle = Bundle.main.path(forResource: "3", ofType: "wav")
            let bundle = Bundle.main.path(forResource: "sound", ofType: "m4a")
            let alertSound = URL(fileURLWithPath: bundle!)
            try AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            try player = AVAudioPlayer(contentsOf: alertSound)

            player?.volume = 0.01
            player?.prepareToPlay()
            player?.play()
            return true
        } catch {
            print(error)
            return false
        }
    }

    func startBackgroundTask() {
        stopBackgroundTask()
        
        guard BackgroundService.isBackgroundNeeded else { return }

        playAudio()
        backgroundTask = UIApplication.shared.beginBackgroundTask(expirationHandler: { [unowned self] () -> Void in
            startBackgroundTask()
        })
    }

    func stopBackgroundTask() {
        if backgroundTask != nil {
            UIApplication.shared.endBackgroundTask(backgroundTask!)
            backgroundTask = nil
        }
    }
}
