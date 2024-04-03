//
//  ConnectionPreferencesViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 02/04/2024.
//

import Combine
import LibTorrent
import MvvmFoundation
import UIKit

class ConnectionPreferencesViewModel: BasePreferencesViewModel {
    required init() {
        super.init()
        reload()
    }

    private let preferences = PreferencesStorage.shared
}

private extension ConnectionPreferencesViewModel {
    func reload() {
        title.send(%"preferences.network.connection")

        var sections: [MvvmCollectionSectionModel] = []
        defer { self.sections.send(sections) }

        sections.append(.init(id: "encryption", header: %"preferences.network.connection.encryption") {
            PRButtonViewModel(with: .init(title: %"preferences.network.connection.encryption.mode", value: preferences.$encryptionPolicy.map(\.name).eraseToAnyPublisher(), accessories: [
                .popUpMenu(
                    .init(title: "Select encryption mode", children: [
                        uiAction(from: .enabled),
                        uiAction(from: .forced),
                        uiAction(from: .disabled),
                    ]), options: .init(tintColor: .tintColor)
                ),
            ]))
        })

        sections.append(.init(id: "protocols", header: %"preferences.network.connection.protocols") {
            PRSwitchViewModel(with: .init(title: %"preferences.network.connection.protocols.dht", value: preferences.$isDhtEnabled.binding))
            PRSwitchViewModel(with: .init(title: %"preferences.network.connection.protocols.lsd", value: preferences.$isLsdEnabled.binding))
            PRSwitchViewModel(with: .init(title: %"preferences.network.connection.protocols.utp", value: preferences.$isUtpEnabled.binding))
            PRSwitchViewModel(with: .init(title: %"preferences.network.connection.protocols.upnp", value: preferences.$isUpnpEnabled.binding))
            PRSwitchViewModel(with: .init(title: %"preferences.network.connection.protocols.nat", value: preferences.$isNatEnabled.binding))
        })

        sections.append(.init(id: "port", header: %"preferences.network.connection.port") {
            PRSwitchViewModel(with: .init(title: %"preferences.network.connection.port.default", value: .init(
                get: { [preferences] in preferences.portBindRetries < 0 },
                set: { [weak self] value in self?.setDefaultPortValue(to: value) }
            )))

            if preferences.portBindRetries >= 0 {
                PRButtonViewModel(with: .init(title: %"preferences.network.connection.port.value", value: preferences.$port.map { String($0) }.eraseToAnyPublisher()) { [unowned self] in
                    textInput(title: "Custom port", placeholder: "6881", defaultValue: "\(preferences.port)", type: .numberPad) { [unowned self] res in
                        dismissSelection.send(())
                        guard let res else { return }
                        preferences.port = Int(res) ?? 6881
                    }
                })
                PRButtonViewModel(with: .init(title: %"preferences.network.connection.port.retries", value: preferences.$portBindRetries.filter { $0 != -1 }.map { String($0) }.eraseToAnyPublisher()) { [unowned self] in
                    textInput(title: "Port retries", placeholder: "10", defaultValue: "\(preferences.portBindRetries)", type: .numberPad) { [unowned self] res in
                        dismissSelection.send(())
                        guard let res else { return }
                        preferences.portBindRetries = Int(res) ?? 10
                    }
                })
            }
        })
    }

    func uiAction(from policy: Session.Settings.EncryptionPolicy) -> UIAction {
        UIAction(title: policy.name, attributes: policy == .disabled ? [.destructive] : [], state: preferences.encryptionPolicy == policy ? .on : .off) { [preferences] _ in preferences.encryptionPolicy = policy }
    }

    func setDefaultPortValue(to value: Bool) {
        preferences.portBindRetries = value ? -1 : 10
        reload()
    }
}

extension Session.Settings.EncryptionPolicy {
    var name: String {
        switch self {
        case .enabled:
            return %"encryptionPolicy.enabled"
        case .forced:
            return %"encryptionPolicy.forced"
        case .disabled:
            return %"encryptionPolicy.disabled"
        @unknown default:
            assertionFailure("Unregistered \(Self.self) enum value is not allowed: \(self)")
            return ""
        }
    }
}
