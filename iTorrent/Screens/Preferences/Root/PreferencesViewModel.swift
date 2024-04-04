//
//  PreferencesViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 06/11/2023.
//

import Combine
import MvvmFoundation
import SwiftUI

class PreferencesViewModel: BasePreferencesViewModel {
    required init() {
        super.init()
        reload()
    }

    private let preferences = PreferencesStorage.shared
}

private extension PreferencesViewModel {
    func reload() {
        title.send(%"preferences")

        var sections: [MvvmCollectionSectionModel] = []
        defer { self.sections.send(sections) }

        sections.append(.init(id: "appearance", header: %"preferences.appearance") {
#if !os(visionOS)
            PRButtonViewModel(with: .init(title: "Application theme", value: preferences.$appAppearance.map(\.name).eraseToAnyPublisher(), accessories: [
                .popUpMenu(
                    .init(title: "Select app theme", children: [
                        uiAction(from: .unspecified),
                        uiAction(from: .light),
                        uiAction(from: .dark),
                    ]), options: .init(tintColor: .tintColor)
                ),
            ]))
#endif
            PRColorPickerViewModel()
            PRButtonViewModel(with: .init(title: %"preferences.appearance.order", accessories: [.disclosureIndicator()]) { [unowned self] in
                navigate(to: PreferencesSectionGroupingViewModel.self, by: .show)
            })
        })

        sections.append(.init(id: "memory", header: %"preferences.storage") {
            PRStorageViewModel()
            PRSwitchViewModel(with: .init(title: %"preferences.storage.allocate", value: preferences.$allocateMemory.binding))
        })

        sections.append(.init(id: "torrentQueueLimits", header: "Torrent queueing limits") {
            PRButtonViewModel(with: .init(title: "Active torrents", value: preferences.$maxActiveTorrents.map { $0 == 0 ? "Unlimited" : "\($0)" }.eraseToAnyPublisher()) { [unowned self] in
                textInput(title: "Active torrents", placeholder: "Unlimited", defaultValue: "\(preferences.maxActiveTorrents)", type: .numberPad) { [unowned self] res in
                    dismissSelection.send(())
                    guard let res else { return }
                    preferences.maxActiveTorrents = Int(res) ?? 0
                }
            })
            PRButtonViewModel(with: .init(title: "Downloading torrents", value: preferences.$maxDownloadingTorrents.map { $0 == 0 ? "Unlimited" : "\($0)" }.eraseToAnyPublisher()) { [unowned self] in
                textInput(title: "Downloading torrents", placeholder: "Unlimited", defaultValue: "\(preferences.maxDownloadingTorrents)", type: .numberPad) { [unowned self] res in
                    dismissSelection.send(())
                    guard let res else { return }
                    preferences.maxDownloadingTorrents = Int(res) ?? 0
                }
            })
            PRButtonViewModel(with: .init(title: "Uploading torrents", value: preferences.$maxUploadingTorrents.map { $0 == 0 ? "Unlimited" : "\($0)" }.eraseToAnyPublisher()) { [unowned self] in
                textInput(title: "Uploading torrents", placeholder: "Unlimited", defaultValue: "\(preferences.maxUploadingTorrents)", type: .numberPad) { [unowned self] res in
                    dismissSelection.send(())
                    guard let res else { return }
                    preferences.maxUploadingTorrents = Int(res) ?? 0
                }
            })
        })

        sections.append(.init(id: "speed limits", header: "Speed limits") {
            PRButtonViewModel(with: .init(title: "Max download speed", value: preferences.$maxDownloadSpeed.map { $0 == 0 ? "Unlimited" : UInt64($0).bitrateToHumanReadable }.eraseToAnyPublisher()) { [unowned self] in
                textInput(title: "Max download speed", message: "Speed in KB/s", placeholder: "Unlimited", defaultValue: "\(preferences.maxDownloadSpeed / 1024)", type: .numberPad) { [unowned self] res in
                    dismissSelection.send(())
                    guard let res else { return }
                    preferences.maxDownloadSpeed = (UInt(res) ?? 0).multipliedReportingOverflow(by: 1024).partialValue
                }
            })
            PRButtonViewModel(with: .init(title: "Max upload speed", value: preferences.$maxUploadSpeed.map { $0 == 0 ? "Unlimited" : UInt64($0).bitrateToHumanReadable }.eraseToAnyPublisher()) { [unowned self] in
                textInput(title: "Max upload speed", message: "Speed in KB/s", placeholder: "Unlimited", defaultValue: "\(preferences.maxUploadSpeed / 1024)", type: .numberPad) { [unowned self] res in
                    dismissSelection.send(())
                    guard let res else { return }
                    preferences.maxUploadSpeed = (UInt(res) ?? 0).multipliedReportingOverflow(by: 1024).partialValue
                }
            })
        })

        sections.append(.init(id: "network", header: %"preferences.network") {
            PRButtonViewModel(with: .init(title: %"preferences.network.proxy", accessories: [.disclosureIndicator()]) { [unowned self] in
                navigate(to: ProxyPreferencesViewModel.self, by: .show)
            })
            PRButtonViewModel(with: .init(title: %"preferences.network.connection", accessories: [.disclosureIndicator()]) { [unowned self] in
                navigate(to: ConnectionPreferencesViewModel.self, by: .show)
            })
        })

        sections.append(.init(id: "notifications", header: %"preferences.notifications") {
            PRSwitchViewModel(with: .init(title: %"preferences.notifications.download", value: preferences.$isDownloadNotificationsEnabled.binding))
            PRSwitchViewModel(with: .init(title: %"preferences.notifications.seed", value: preferences.$isSeedNotificationsEnabled.binding))
        })

        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let appBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        let libtorrentVersion = TorrentService.version
        let version = "iTorrent: v\(appVersion)-\(appBuild) | LibTorrent: v\(libtorrentVersion)"
        sections.append(.init(id: "version", header: "Version", footer: version, style: .insetGrouped) {
            PRButtonViewModel(with: .init(title: "GitHub page", value: Just("Open").eraseToAnyPublisher(), selectAction: { [unowned self] in
                UIApplication.shared.open(.init(string: "https://github.com/XITRIX/iTorrent")!)
                dismissSelection.send(())
            }))
        })
    }

    func uiAction(from interfaceStyle: UIUserInterfaceStyle) -> UIAction {
        UIAction(title: interfaceStyle.name, state: preferences.appAppearance == interfaceStyle ? .on : .off) { [preferences] _ in
            preferences.appAppearance = interfaceStyle
        }
    }
}

private extension UIUserInterfaceStyle {
    var name: String {
        switch self {
        case .unspecified:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        @unknown default:
            assertionFailure("Unregistered \(Self.self) enum value is not allowed: \(self)")
            return ""
        }
    }
}
