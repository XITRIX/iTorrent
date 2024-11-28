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
    private var asyncTask: Task<Void, Error>?
}

extension AudioBackgroundService: BackgroundServiceProtocol {
    var isRunning: Bool {
        (player?.isPlaying ?? false) || (backgroundTask != nil && backgroundTask != .invalid)
    }
    
    func start() -> Bool {
        guard !isRunning else { return true }
        startBackgroundTask()
        NotificationCenter.default.addObserver(self, selector: #selector(interruptedAudio), name: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance())
        return true
    }

    func stop() {
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
        asyncTask?.cancel()
        stopBackgroundTask()
        stopAudio()
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

    static func cratePlayer() throws -> AVAudioPlayer {
        //            let bundle = Bundle.main.path(forResource: "3", ofType: "wav")
        let bundle = Bundle.main.path(forResource: "sound", ofType: "m4a")
        let alertSound = URL(fileURLWithPath: bundle!)
        try AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
        try AVAudioSession.sharedInstance().setActive(true)
        let player = try AVAudioPlayer(contentsOf: alertSound)
        player.volume = 0.01
        player.numberOfLoops = -1
        return player
    }

    func getPlayer() throws -> AVAudioPlayer {
        if let player {
            return player
        }

        let newPlayer = try Self.cratePlayer()
        player = newPlayer
        return newPlayer
    }

    @discardableResult
    func playAudio() -> Bool {
        do {
            let player = try getPlayer()
//            player.prepareToPlay()
            player.play()
            return true
        } catch {
            print(error)
            return false
        }
    }

    func stopAudio() {
        player?.stop()
    }

    func startBackgroundTask() {
        guard BackgroundService.isBackgroundNeeded else {
            stopBackgroundTask()
            stopAudio()
            return
        }

        asyncTask = Task {
            playAudio()
            stopBackgroundTask()
            
            backgroundTask = await UIApplication.shared.beginBackgroundTask { [weak self] in
                guard let self else { return }
                print("\(Date.now.timestamp) [BG] timeout!!!")
                startBackgroundTask()
            }

            stopAudio()
            try Task.checkCancellation()

            // If cannot start BG try again
            guard backgroundTask != .invalid else { return startBackgroundTask() }
            print("\(Date.now.timestamp) [BG] running!!!")
            try await Task.sleep(for: .seconds(10))
            startBackgroundTask()
        }
    }

    func stopBackgroundTask() {
        if backgroundTask != nil {
            UIApplication.shared.endBackgroundTask(backgroundTask!)
            backgroundTask = nil
        }
    }
}

extension Date {
    var timestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSSZZZZZ"
        return formatter.string(from: self)
    }
}
