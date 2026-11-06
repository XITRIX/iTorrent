//
//  AudioBackgroundService.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 05/04/2024.
//

import AVFoundation
import UIKit

@MainActor
class AudioBackgroundService {
    private var player: AVAudioPlayer?
    private var backgroundTask: UIBackgroundTaskIdentifier?
    private var asyncTask: Task<Void, Never>?
    private var isStarted = false
}

extension AudioBackgroundService: BackgroundServiceProtocol {
    var isRunning: Bool {
        isStarted
    }
    
    func start() -> Bool {
        guard !isRunning else { return true }
        isStarted = true
        NotificationCenter.default.addObserver(self, selector: #selector(interruptedAudio), name: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance())
        startBackgroundTask()
        return isRunning
    }

    func stop() {
        isStarted = false
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
        replaceAsyncTask(with: nil)
        stopBackgroundTask()
        stopAudio()
    }
    
    func prepare() async -> Bool { true }
}

private extension AudioBackgroundService {
    @objc nonisolated func interruptedAudio(_ notification: Notification) {
        guard notification.name == AVAudioSession.interruptionNotification,
              let typeValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else {
            return
        }

        Task { @MainActor [weak self] in
            self?.handleInterruption(type)
        }
    }

    func handleInterruption(_ type: AVAudioSession.InterruptionType) {
        guard isStarted else { return }
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
        guard isStarted else { return }
        guard BackgroundService.isBackgroundNeeded else {
            stop()
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
            guard isStarted, BackgroundService.isBackgroundNeeded else {
                stop()
                return
            }

            playAudio()
            stopBackgroundTask()

            backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
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
        let previousTask = asyncTask
        asyncTask = task

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
