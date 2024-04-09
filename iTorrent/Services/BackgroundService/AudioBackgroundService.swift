//
//  AudioBackgroundService.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 05/04/2024.
//

import AVFoundation

@MainActor
class AudioBackgroundService {
    private var player: AVAudioPlayer?
}

extension AudioBackgroundService: BackgroundServiceProtocol {
    var isRunning: Bool {
        player?.isPlaying ?? false
    }
    
    func start() -> Bool {
        guard !isRunning else { return true }
        guard playAudio() else { return false }
        NotificationCenter.default.addObserver(self, selector: #selector(interruptedAudio), name: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance())
        return true
    }

    func stop() {
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
            let bundle = Bundle.main.path(forResource: "3", ofType: "wav")
            let alertSound = URL(fileURLWithPath: bundle!)
            try AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            try player = AVAudioPlayer(contentsOf: alertSound)

            player?.numberOfLoops = -1
            player?.volume = 0.01
            player?.prepareToPlay()
            player?.play()
            return true
        } catch {
            print(error)
            return false
        }
    }
}
