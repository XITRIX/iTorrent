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
#else
// Mock for CoreTelephony enum state for unsupported platforms
enum CTCellularDataRestrictedState {
    case restrictedStateUnknown
    case restricted
    case notRestricted
}
#endif

class NetworkMonitoringService {
    // Raw cellular availability, ignores app and system restrictions
    @Published var isCellularAvailable: Bool = false
    @Published var availableInterfaces: [NWInterface] = []
    @Published var cellularState: CTCellularDataRestrictedState = .restrictedStateUnknown

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
        preferences.$isCellularEnabled.receive(on: DispatchQueue.main).sink { [unowned self] _ in
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
        let isCellularRestricted = false
#endif

        let isCellularAvailableUpdate = monitor.currentPath.availableInterfaces.contains(where: { $0.type == .cellular })
        if isCellularAvailable != isCellularAvailableUpdate {
            isCellularAvailable = isCellularAvailableUpdate
        }

        let updatedInterfaces: [NWInterface]

        // If cellular restricted and there is no WiFi or Wired interface
        // remove all interfaces to prevent VPN interface from working throw Cellular
        if isCellularRestricted, !monitor.currentPath.availableInterfaces.contains(where: { Self.nonCellularTypes.contains($0.type) }) {
            updatedInterfaces = []
        } else {
            updatedInterfaces = monitor.currentPath.availableInterfaces
        }

        // Do not notify duplicates, otherwise iTorrent will drop connection for nothing
        guard availableInterfaces != updatedInterfaces else { return }
        availableInterfaces = updatedInterfaces
    }

    static let nonCellularTypes: [NWInterface.InterfaceType] = [.wifi, .wiredEthernet]
}
