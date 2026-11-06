//
//  LocationBackgroundService.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 05/04/2024.
//

import CoreLocation

@MainActor
class LocationBackgroundService: NSObject {
    override init() {
        super.init()
        locationManager.delegate = self
    }

    var isRunning: Bool = false

    private var continuations: [CheckedContinuation<Void, Never>] = []
    private let locationManager = CLLocationManager()
}

extension LocationBackgroundService: BackgroundServiceProtocol {
    func start() -> Bool {
        guard !isRunning else { return true }

        isRunning = runLocationService()
        return isRunning
    }
    
    func stop() {
        locationManager.stopUpdatingLocation()
        isRunning = false
    }

    func prepare() async -> Bool {
        var status = locationManager.authorizationStatus
        guard status == .notDetermined else {
            return status != .denied && status != .restricted
        }

        await withCheckedContinuation { continuation in
            let shouldRequestAuthorization = continuations.isEmpty
            continuations.append(continuation)
#if !os(visionOS)
            if shouldRequestAuthorization {
                locationManager.requestAlwaysAuthorization()
            }
#else
            finishAuthorization()
#endif
        }

        status = locationManager.authorizationStatus
        return status != .restricted && status != .denied && status != .notDetermined
    }
}

private extension LocationBackgroundService {
    func finishAuthorization() {
        let pending = continuations
        continuations.removeAll()
        pending.forEach { $0.resume() }
    }

    func runLocationService() -> Bool {
        locationManager.desiredAccuracy = kCLLocationAccuracyReduced

        let status = locationManager.authorizationStatus
        guard status != .restricted && status != .denied
        else { return false }

#if !os(visionOS)
        locationManager.allowsBackgroundLocationUpdates = true
#endif
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.showsBackgroundLocationIndicator = PreferencesStorage.shared.isBackgroundLocationIndicatorEnabled
        locationManager.startUpdatingLocation()
        return true
    }
}

extension LocationBackgroundService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard manager.authorizationStatus != .notDetermined
        else { return }

        Task { @MainActor [weak self] in
            guard let self else { return }
            finishAuthorization()
        }
    }
}
