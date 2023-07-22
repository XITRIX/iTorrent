//
//  BackgroundTask.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 19.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import AVFoundation
import CoreLocation
import UIKit

#if TRANSMISSION
import ITorrentTransmissionFramework
#else
import ITorrentFramework
#endif

class BackgroundTask: NSObject {
    public static let shared = BackgroundTask()
    var backgrounding: Bool {
        currentBackgroundMode != nil
    }

    private var player: AVAudioPlayer?

    private let locationManager = CLLocationManager()
    private var currentBackgroundMode: BackgroundTask.Mode?
    private var locationManagerCompletion: ((CLAuthorizationStatus) -> ())?

    override init() {
        super.init()
        locationManager.delegate = self
    }

    func stopBackgroundTask() {
        if let currentBackgroundMode {
            switch currentBackgroundMode {
            case .audio:
                stopWithAudio()
            case .location:
                stopWithLocation()
            }
        }

        currentBackgroundMode = nil
    }

    func startBackground() -> Bool {
        if UserPreferences.background,
           Core.shared.torrents.values.contains(where: { status -> Bool in
               BackgroundTask.getBackgroundConditions(status)
           })
        {
            startBackgroundTask()
            return true
        }
        return false
    }

    func checkToStopBackground() {
        if backgrounding {
            if !Core.shared.torrents.values.contains(where: { BackgroundTask.getBackgroundConditions($0) }) {
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

extension BackgroundTask {
    enum Mode: Codable {
        case audio
        case location
    }
}

extension BackgroundTask.Mode {
    var name: String {
        switch self {
        case .audio:
            return "BackgroundTask.Mode.Audio".localized
        case .location:
            return "BackgroundTask.Mode.Location".localized
        }
    }
}

private extension BackgroundTask {
    func startBackgroundTask() {
        if !backgrounding {
            switch UserPreferences.backgroundMode {
            case .audio:
                startWithAudio()
            case .location:
                startWithLocation()
            }
        }
    }
}

// MARK: - Location background stuff
private extension BackgroundTask {
    func startWithLocation() {
        if #available(iOS 14.0, *) {
            locationManager.desiredAccuracy = kCLLocationAccuracyReduced

            let status = locationManager.authorizationStatus
            guard status != .restricted && status != .denied
            else {
                UserPreferences.backgroundMode = .audio
                startWithAudio()
                return
            }
        } else {
            locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        }

        currentBackgroundMode = .location
        locationManager.requestWhenInUseAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.startUpdatingLocation()
        locationManager.showsBackgroundLocationIndicator = false
    }

    func stopWithLocation() {
        locationManager.stopUpdatingLocation()
    }
}

extension BackgroundTask {
    func requestPermissions(from context: UIViewController, completion: ((CLAuthorizationStatus) -> ())? = nil) {
        if #available(iOS 14.0, *) {
            let status = self.locationManager.authorizationStatus

            if status == .notDetermined {
                locationManagerCompletion = completion
                self.locationManager.requestWhenInUseAuthorization()
                return
            }

            if status == .restricted || status == .denied {
                let alert = ThemedUIAlertController(title: "Permission not granted", message: "You rejected location permissions earlier, to allow iTorrent to use location manager go to Settings -> iTonnret and allow it to use location services", preferredStyle: .alert)
                alert.addAction(.init(title: "OK", style: .cancel))
                context.present(alert, animated: true)
            }

            completion?(status)
        }
    }
}

// MARK: - Audio background stuff
private extension BackgroundTask {
    func startWithAudio() {
        currentBackgroundMode = .audio
        NotificationCenter.default.addObserver(self, selector: #selector(interruptedAudio), name: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance())
        playAudio()
    }

    func stopWithAudio() {
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
        player?.stop()
    }

    @objc func interruptedAudio(_ notification: Notification) {
        if notification.name == AVAudioSession.interruptionNotification,
           let info = notification.userInfo
        {
            var intValue = 0
            let key = info[AVAudioSessionInterruptionTypeKey] as AnyObject
            key.getValue(&intValue)
            if intValue == 1 { playAudio() }
        }
    }

    func playAudio() {
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
        } catch {
            print(error)
        }
    }
}

extension BackgroundTask: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if #available(iOS 14.0, *) {
            locationManagerCompletion?(manager.authorizationStatus)
            locationManagerCompletion = nil
        }
    }
}
