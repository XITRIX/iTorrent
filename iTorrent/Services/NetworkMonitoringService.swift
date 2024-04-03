//
//  NetworkMonitoringService.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 02.04.2024.
//

import Foundation
import Combine
import Network
#if canImport(CoreTelephony)
import CoreTelephony
#endif

class NetworkMonitoringService {
    @Published var availableInterfaces: [NWInterface] = []
#if canImport(CoreTelephony)
    @Published var cellularState: CTCellularDataRestrictedState = .restrictedStateUnknown
#endif

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            updateAvailableInterfaces()
        }

#if canImport(CoreTelephony)
        cellularData.cellularDataRestrictionDidUpdateNotifier = { [weak self] newState in
            guard let self else { return }
            cellularState = newState
            updateAvailableInterfaces()
        }
#endif

        let queue = DispatchQueue.init(label: "monitor queue", qos: .userInitiated)
        monitor.start(queue: queue)
    }

    private let monitor = NWPathMonitor()
#if canImport(CoreTelephony)
    private let cellularData = CTCellularData()
#endif
}

private extension NetworkMonitoringService {
    func updateAvailableInterfaces() {
#if canImport(CoreTelephony)
        let isCellularRestricted = cellularData.restrictedState == .restricted
#else
        let isCellularRestricted = false
#endif
        availableInterfaces = monitor.currentPath.availableInterfaces.filter { $0.type != .cellular || !isCellularRestricted }
    }
}
