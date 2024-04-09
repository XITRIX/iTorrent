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

    private var continuation: CheckedContinuation<Void, Never>?
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

        locationManager.requestWhenInUseAuthorization()
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }

        status = locationManager.authorizationStatus
        return status != .restricted && status != .denied && status != .notDetermined
    }
}

private extension LocationBackgroundService {
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
        locationManager.showsBackgroundLocationIndicator = false
        locationManager.startUpdatingLocation()
        return true
    }
}

extension LocationBackgroundService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard manager.authorizationStatus != .notDetermined
        else { return }

        Task {
            await continuation?.resume()
//            continuation = nil
        }
    }
}
