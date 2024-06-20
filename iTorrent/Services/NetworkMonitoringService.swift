//
//  NetworkMonitoringService.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 02.04.2024.
//

import Combine
import Foundation
import MvvmFoundation
import Network
#if canImport(CoreTelephony)
import CoreTelephony
#endif

class NetworkMonitoringService {
    @Published var availableInterfaces: [NWInterface] = []
#if canImport(CoreTelephony) && !targetEnvironment(macCatalyst)
    @Published var cellularState: CTCellularDataRestrictedState = .restrictedStateUnknown
#endif

    init() {
        monitor.pathUpdateHandler = { [weak self] _ in
            guard let self else { return }
            updateAvailableInterfaces()
        }

#if canImport(CoreTelephony) && !targetEnvironment(macCatalyst)
        cellularData.cellularDataRestrictionDidUpdateNotifier = { [weak self] newState in
            guard let self else { return }
            cellularState = newState
            updateAvailableInterfaces()
        }
#endif
        preferences.$isCellularEnabled.sink { [unowned self] _ in
            updateAvailableInterfaces()
        }.store(in: disposeBag)

        let queue = DispatchQueue(label: "monitor queue", qos: .userInitiated)
        monitor.start(queue: queue)
    }

    private let disposeBag = DisposeBag()
    private let monitor = NWPathMonitor()
#if canImport(CoreTelephony) && !targetEnvironment(macCatalyst)
    private let cellularData = CTCellularData()
#endif
    @Injected private var preferences: PreferencesStorage
}

private extension NetworkMonitoringService {
    func updateAvailableInterfaces() {
#if canImport(CoreTelephony) && !targetEnvironment(macCatalyst)
        let isCellularRestricted = cellularData.restrictedState == .restricted || !preferences.isCellularEnabled
#else
        let isCellularRestricted = !preferences.isCellularEnabled
#endif

        let updatedInterfaces = monitor.currentPath.availableInterfaces.filter { $0.type != .cellular || !isCellularRestricted }

        // Do not notify duplicates, otherwise iTorrent will drop connection for nothing
        guard availableInterfaces != updatedInterfaces else { return }
        availableInterfaces = updatedInterfaces
    }
}
