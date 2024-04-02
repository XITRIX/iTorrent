//
//  NetworkMonitoringService.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 02.04.2024.
//

import Foundation
import Combine
import Network
import CoreTelephony

class NetworkMonitoringService {
    @Published var availableInterfaces: [NWInterface] = []
    @Published var cellularState: CTCellularDataRestrictedState = .restrictedStateUnknown

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            updateAvailableInterfaces()
        }

        cellularData.cellularDataRestrictionDidUpdateNotifier = { [weak self] newState in
            guard let self else { return }
            cellularState = newState
            updateAvailableInterfaces()
        }

        let queue = DispatchQueue.init(label: "monitor queue", qos: .userInitiated)
        monitor.start(queue: queue)
    }

    private let monitor = NWPathMonitor()
    private let cellularData = CTCellularData()
}

private extension NetworkMonitoringService {
    func updateAvailableInterfaces() {
        availableInterfaces = monitor.currentPath.availableInterfaces.filter { $0.type != .cellular || cellularData.restrictedState != .restricted }
    }
}
