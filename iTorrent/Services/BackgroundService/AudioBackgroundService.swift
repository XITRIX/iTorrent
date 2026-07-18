//
//  AudioBackgroundService.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 05/04/2024.
//

import AVFoundation
import UIKit

class AudioBackgroundService: @unchecked Sendable {
    private var player: AVAudioPlayer?
    private var backgroundTask: UIBackgroundTaskIdentifier?
    private var asyncTask: Task<Void, Never>?
    private let asyncTaskLock = NSLock()
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
        replaceAsyncTask(with: nil)
        stopBackgroundTask()
        stopAudio()
    }
    
    func prepare() async -> Bool { true }
}

private extension AudioBackgroundService {
    @objc func interruptedAudio(_ notification: Notification) {
        guard notification.name == AVAudioSession.interruptionNotification,
              let typeValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else {
            return
        }

        switch type {
        case .began:
            // Keep the service alive while the system owns the audio session.
            break
        case .ended:
            // This is not user-controlled media playback, so background demand—not
            // AVAudioSessionInterruptionOptionShouldResume—determines whether to resume.
            guard BackgroundService.isBackgroundNeeded else { return }

            do {
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("\(Date.now.timestamp) [BG] failed to reactivate audio session: \(error)")
            }
            startBackgroundTask()
        @unknown default:
            break
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

        let task = Task { [weak self] in
            guard let self else { return }
            await runBackgroundTask()
        }
        replaceAsyncTask(with: task)
    }

    func runBackgroundTask() async {
        while !Task.isCancelled {
            guard BackgroundService.isBackgroundNeeded else {
                stopBackgroundTask()
                stopAudio()
                return
            }

            playAudio()
            stopBackgroundTask()

            backgroundTask = await UIApplication.shared.beginBackgroundTask { [weak self] in
                guard let self else { return }
                print("\(Date.now.timestamp) [BG] timeout!!!")
                startBackgroundTask()
            }

            stopAudio()
            guard !Task.isCancelled else { return }

            // If cannot start BG try again
            guard backgroundTask != .invalid else { continue }
            print("\(Date.now.timestamp) [BG] running!!!")
            do {
                try await Task.sleep(for: .seconds(10))
            } catch {
                return
            }
        }
    }

    func replaceAsyncTask(with task: Task<Void, Never>?) {
        asyncTaskLock.lock()
        let previousTask = asyncTask
        asyncTask = task
        asyncTaskLock.unlock()

        previousTask?.cancel()
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
