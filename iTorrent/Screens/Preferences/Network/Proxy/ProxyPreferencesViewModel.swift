//
//  ProxyPreferencesViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 02/04/2024.
//

import MvvmFoundation
import LibTorrent
import UIKit

class ProxyPreferencesViewModel: BasePreferencesViewModel {
    required init() {
        super.init()
        binding()
        reload()
    }

    private let preferences = PreferencesStorage.shared
}

private extension ProxyPreferencesViewModel {
    func binding() {
        disposeBag.bind {
            preferences.$proxyAuthRequired.sink(receiveValue: { [unowned self] _ in reload() })
        }
    }

    func reload() {
        title.send(%"preferences.network.proxy")
        
        var sections: [MvvmCollectionSectionModel] = []
        defer { self.sections.send(sections) }

        sections.append(.init(id: "host", header: %"preferences.network.proxy.host") {
            PRButtonViewModel(with: .init(title: %"preferences.network.proxy.host.type", value: preferences.$proxyType.map(\.name).eraseToAnyPublisher(), accessories: [
                .popUpMenu(
                    .init(title: %"preferences.network.proxy.host.type.action", children: [
                        uiAction(from: .none),
                        uiAction(from: .socks4),
                        uiAction(from: .socks5),
                        uiAction(from: .http),
                        uiAction(from: .i2p_proxy),
                    ]), options: .init(tintColor: .tintColor)
                ),
            ]))

            if preferences.proxyType != .none {
                PRButtonViewModel(with: .init(title: %"preferences.network.proxy.host.name", value: preferences.$proxyHostname.eraseToAnyPublisher()) { [unowned self] in
                    textInput(title: %"preferences.network.proxy.host.name", placeholder: "Hostname", defaultValue: "\(preferences.proxyHostname)", type: .URL) { [unowned self] res in
                        dismissSelection.send()
                        guard let res else { return }
                        preferences.proxyHostname = res
                    }
                })
                PRButtonViewModel(with: .init(title: %"common.port", value: preferences.$proxyHostPort.map { String($0) }.eraseToAnyPublisher()) { [unowned self] in
                    textInput(title: %"common.port", placeholder: "8080", defaultValue: "\(preferences.proxyHostPort)", type: .numberPad) { [unowned self] res in
                        dismissSelection.send()
                        guard let res else { return }
                        preferences.proxyHostPort = Int(res) ?? 8080
                    }
                })
            }
        })

        if preferences.proxyType != .none {
            sections.append(.init(id: "auth", header: %"preferences.network.proxy.auth") {
                PRSwitchViewModel(with: .init(title: %"preferences.network.proxy.auth.required", value: preferences.$proxyAuthRequired.binding))

                if preferences.proxyAuthRequired {
                    PRButtonViewModel(with: .init(title: %"common.login", value: preferences.$proxyUsername.eraseToAnyPublisher()) { [unowned self] in
                        textInput(title: %"common.login", placeholder: "admin", defaultValue: "\(preferences.proxyUsername)", type: .URL) { [unowned self] res in
                            dismissSelection.send()
                            guard let res else { return }
                            preferences.proxyUsername = res
                        }
                    })
                    PRButtonViewModel(with: .init(title: %"common.password", value: preferences.$proxyPassword.map { String($0).map { _ in "•" }.joined() }.eraseToAnyPublisher()) { [unowned self] in
                        textInput(title: %"common.password", placeholder: "12345", defaultValue: "\(preferences.proxyPassword)", type: .default, secured: true) { [unowned self] res in
                            dismissSelection.send()
                            guard let res else { return }
                            preferences.proxyPassword = res
                        }
                    })
                }
            })
        }
    }

    func uiAction(from proxyType: Session.Settings.ProxyType) -> UIAction {
        MainActor.assumeIsolated {
            UIAction(title: proxyType.name, state: preferences.proxyType == proxyType ? .on : .off) { [unowned self] _ in
                preferences.proxyType = proxyType
                reload()
            }
        }
    }
}

extension Session.Settings.ProxyType {
    var name: String {
        switch self {
        case .none:
            return %"proxyType.none"
        case .socks4:
            return %"proxyType.socks4"
        case .socks5:
            return %"proxyType.socks5"
        case .http:
            return %"proxyType.http"
        case .i2p_proxy:
            return %"proxyType.i2p_proxy"
        @unknown default:
            assertionFailure("Unregistered \(Self.self) value is not allowed: \(self)")
            return ""
        }
    }
}
