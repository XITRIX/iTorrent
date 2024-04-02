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
                    ]), options: .init(tintColor: .tintColor)),
            ]))
        })

        sections.append(.init(id: "protocols", header: %"preferences.network.connection.protocols") {
            PRSwitchViewModel(with: .init(title: %"preferences.network.connection.protocols.dht", value: preferences.$isDhtEnabled.binding))
            PRSwitchViewModel(with: .init(title: %"preferences.network.connection.protocols.lsd", value: preferences.$isLsdEnabled.binding))
            PRSwitchViewModel(with: .init(title: %"preferences.network.connection.protocols.utp", value: preferences.$isUtpEnabled.binding))
            PRSwitchViewModel(with: .init(title: %"preferences.network.connection.protocols.upnp", value: preferences.$isUpnpEnabled.binding))
            PRSwitchViewModel(with: .init(title: %"preferences.network.connection.protocols.nat", value: preferences.$isNatEnabled.binding))
        })
    }

    func uiAction(from policy: Session.Settings.EncryptionPolicy) -> UIAction {
        UIAction(title: policy.name, attributes: policy == .disabled ? [.destructive] : [], state: preferences.encryptionPolicy == policy ? .on : .off) { [preferences] _ in preferences.encryptionPolicy = policy }
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
            assertionFailure("Unregistered EncryptionPolicy enum value is not allowed: \(self)")
            return ""
        }
    }
}
