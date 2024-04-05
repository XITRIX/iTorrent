//
//  LocationBackgroundService.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 05/04/2024.
//

import CoreLocation

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

//        if status == .restricted || status == .denied {
//            let alert = ThemedUIAlertController(title: "Permission not granted", message: "You rejected location permissions earlier, to allow iTorrent to use location manager go to Settings -> iTonnret and allow it to use location services", preferredStyle: .alert)
//            alert.addAction(.init(title: "OK", style: .cancel))
//            context.present(alert, animated: true)
//        }
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
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard manager.authorizationStatus != .notDetermined
        else { return }

        continuation?.resume()
        continuation = nil
    }
}
