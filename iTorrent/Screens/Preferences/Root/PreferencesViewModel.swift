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
        binding()
        reload()
    }

    private let colorPickerVM = PRColorPickerViewModel()
    private let storageVM = PRStorageViewModel()

    @Injected private var preferences: PreferencesStorage
    @Injected private var webServerService: WebServerService
}

private extension PreferencesViewModel {
    func binding() {
        disposeBag.bind {
            preferences.$backgroundMode
                .receive(on: .main)
                .sink { [unowned self] _ in
                    reload()
                }
        }
    }

    func reload() {
        title.send(%"preferences")

        var sections: [MvvmCollectionSectionModel] = []
        defer { self.sections.send(sections) }

        sections.append(.init(id: "appearance", header: %"preferences.appearance") {
#if !os(visionOS)
            PRButtonViewModel(with: .init(title: %"preferences.appearance.theme", value: preferences.$appAppearance.map(\.name).eraseToAnyPublisher(), accessories: [
                .popUpMenu(
                    .init(title: %"preferences.appearance.theme.action", children: [
                        uiAction(from: .unspecified),
                        uiAction(from: .light),
                        uiAction(from: .dark),
                    ]), options: .init(tintColor: .tintColor)
                ),
            ]))
#endif
            colorPickerVM
            PRButtonViewModel(with: .init(title: %"preferences.appearance.order", accessories: [.disclosureIndicator()]) { [unowned self] in
                navigate(to: PreferencesSectionGroupingViewModel.self, by: .show)
            })
        })

        sections.append(.init(id: "memory", header: %"preferences.storage") {
            storageVM
            PRButtonViewModel(with: .init(title: %"preferences", accessories: [.disclosureIndicator()]) { [unowned self] in
                navigate(to: StoragePreferencesViewModel.self, by: .show)
            })
//            PRButtonViewModel(with: .init(title: "preferences2", accessories: [.disclosureIndicator()]) { [unowned self] in
//                navigate(to: StoragePreferencesViewModel.self, by: .show)
////                navigate(to: SUIStoragePreferencesViewModel.self, by: .show)
//            })
        })

#if IS_SUPPORT_LOCATION_BG
        sections.append(.init(id: "background", header: %"preferences.background") {
            PRSwitchViewModel(with: .init(title: %"preferences.background.enable", value: preferences.$isBackgroundDownloadEnabled.binding))
            PRButtonViewModel(with: .init(title: %"preferences.background.mode", value: preferences.$backgroundMode.map(\.name).eraseToAnyPublisher(), accessories: [
                .popUpMenu(
                    .init(title: %"preferences.background.mode.action", children: [
                        uiAction(from: .audio),
                        uiAction(from: .location),
                    ]), options: .init(tintColor: .tintColor)
                ),
            ]))

            if preferences.backgroundMode == .location {
                PRSwitchViewModel(with: .init(title: %"preferences.background.location.indicator.enable", value: preferences.$isBackgroundLocationIndicatorEnabled.binding))
            }
        })
#endif

        sections.append(.init(id: "seeding", header: %"preferences.seeding") {
            PRSwitchViewModel(with: .init(title: %"preferences.seeding.stopOnFinish", value: preferences.$stopSeedingOnFinish.binding, isDangerous: true))
        })

        sections.append(.init(id: "torrentQueueLimits", header: %"preferences.queueLimits") {
            PRButtonViewModel(with: .init(title: %"preferences.queueLimits.active", value: preferences.$maxActiveTorrents.map { $0 == 0 ? %"preferences.speedLimits.unlimited" : "\($0)" }.eraseToAnyPublisher()) { [unowned self] in
                textInput(title: %"preferences.queueLimits.active", placeholder: %"preferences.speedLimits.unlimited", defaultValue: "\(preferences.maxActiveTorrents)", type: .numberPad) { [unowned self] res in
                    dismissSelection.send()
                    guard let res else { return }
                    preferences.maxActiveTorrents = Int(res) ?? 0
                }
            })
            PRButtonViewModel(with: .init(title: %"preferences.queueLimits.downloading", value: preferences.$maxDownloadingTorrents.map { $0 == 0 ? %"preferences.speedLimits.unlimited" : "\($0)" }.eraseToAnyPublisher()) { [unowned self] in
                textInput(title: %"preferences.queueLimits.downloading", placeholder: %"preferences.speedLimits.unlimited", defaultValue: "\(preferences.maxDownloadingTorrents)", type: .numberPad) { [unowned self] res in
                    dismissSelection.send()
                    guard let res else { return }
                    preferences.maxDownloadingTorrents = Int(res) ?? 0
                }
            })
            PRButtonViewModel(with: .init(title: %"preferences.queueLimits.uploading", value: preferences.$maxUploadingTorrents.map { $0 == 0 ? %"preferences.speedLimits.unlimited" : "\($0)" }.eraseToAnyPublisher()) { [unowned self] in
                textInput(title: %"preferences.queueLimits.uploading", placeholder: %"preferences.speedLimits.unlimited", defaultValue: "\(preferences.maxUploadingTorrents)", type: .numberPad) { [unowned self] res in
                    dismissSelection.send()
                    guard let res else { return }
                    preferences.maxUploadingTorrents = Int(res) ?? 0
                }
            })
        })

        sections.append(.init(id: "speed limits", header: %"preferences.speedLimits") {
            PRButtonViewModel(with: .init(title: %"preferences.speedLimits.download", value: preferences.$maxDownloadSpeed.map { $0 == 0 ? %"preferences.speedLimits.unlimited" : UInt64($0).bitrateToHumanReadable }.eraseToAnyPublisher()) { [unowned self] in
                textInput(title: %"preferences.speedLimits.download", message: %"preferences.speedLimits.hint", placeholder: %"preferences.speedLimits.unlimited", defaultValue: "\(preferences.maxDownloadSpeed / 1024)", type: .numberPad) { [unowned self] res in
                    dismissSelection.send()
                    guard let res else { return }
                    preferences.maxDownloadSpeed = (UInt(res) ?? 0).multipliedReportingOverflow(by: 1024).partialValue
                }
            })
            PRButtonViewModel(with: .init(title: %"preferences.speedLimits.upload", value: preferences.$maxUploadSpeed.map { $0 == 0 ? %"preferences.speedLimits.unlimited" : UInt64($0).bitrateToHumanReadable }.eraseToAnyPublisher()) { [unowned self] in
                textInput(title: %"preferences.speedLimits.upload", message: %"preferences.speedLimits.hint", placeholder: %"preferences.speedLimits.unlimited", defaultValue: "\(preferences.maxUploadSpeed / 1024)", type: .numberPad) { [unowned self] res in
                    dismissSelection.send()
                    guard let res else { return }
                    preferences.maxUploadSpeed = (UInt(res) ?? 0).multipliedReportingOverflow(by: 1024).partialValue
                }
            })
        })

        sections.append(.init(id: "filesharing", header: .init(%"preferences.sharing"), footer: webServerService.connectionHint) {
            PRSwitchViewModel(with: .init(id: "filesharingswitch", title: %"common.enable", value: preferences.$isFileSharingEnabled.binding))
            PRButtonViewModel(with: .init(id: "filesharingbutton", title: %"preferences", accessories: [.disclosureIndicator()]) { [unowned self] in
                navigate(to: FileSharingPreferencesViewModel.self, by: .show)
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

            // Finish seeding automatically is not possible for now
//            PRSwitchViewModel(with: .init(title: %"preferences.notifications.seed", value: preferences.$isSeedNotificationsEnabled.binding))
        })

        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let appBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        let libtorrentVersion = TorrentService.version
        let version = "iTorrent: v\(appVersion)-\(appBuild) | LibTorrent: v\(libtorrentVersion)"
        sections.append(.init(id: "version", header: %"preferences.version", footer: version, style: .insetGrouped) {
            PRButtonViewModel(with: .init(title: %"preferences.version.github", value: Just(%"common.open").eraseToAnyPublisher(), selectAction: { [unowned self] in
                UIApplication.shared.open(.init(string: "https://github.com/XITRIX/iTorrent")!)
                dismissSelection.send()
            }))
        })

        sections.append(.init(id: "donations", header: %"preferences.donations") {
            PRButtonViewModel(with: .init(title: %"preferences.donations.patreon", accessories: [.disclosureIndicator()]) { [unowned self] in
                navigate(to: PatreonPreferencesViewModel.self, by: .show)
            })
        })
    }

    func uiAction(from interfaceStyle: UIUserInterfaceStyle) -> UIAction {
        UIAction(title: interfaceStyle.name, state: preferences.appAppearance == interfaceStyle ? .on : .off) { [unowned self] _ in
            updateAppearance(with: interfaceStyle)
        }
    }

    func uiAction(from backgroundMode: BackgroundService.Mode) -> UIAction {
        UIAction(title: backgroundMode.name, state: preferences.backgroundMode == backgroundMode ? .on : .off) { [preferences] _ in
            preferences.backgroundMode = backgroundMode
        }
    }

    func updateAppearance(with interfaceStyle: UIUserInterfaceStyle) {
        guard let vc = navigationService?(),
              let window = vc.view.window
        else { // Dirty way to access VC
            preferences.appAppearance = interfaceStyle
            return
        }

        let currentAppTheme = window.traitCollection.userInterfaceStyle
        let currentDeviceTheme = window.windowScene!.traitCollection.userInterfaceStyle

        let animationNeeded: Bool
        if interfaceStyle == .unspecified {
            animationNeeded = currentAppTheme != currentDeviceTheme
        } else {
            animationNeeded = currentAppTheme != interfaceStyle
        }

        guard animationNeeded else {
            preferences.appAppearance = interfaceStyle
            return
        }

        window.isUserInteractionEnabled = false
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2) { [self] in
            CircularAnimation.animate(startingPoint: .init(x: window.frame.width / 2, y: -60)) {
                preferences.appAppearance = interfaceStyle
            } completion: {
                window.isUserInteractionEnabled = true
            }
        }
    }
}

private extension UIUserInterfaceStyle {
    var name: String {
        switch self {
        case .unspecified:
            return %"preferences.appearance.theme.system"
        case .light:
            return %"preferences.appearance.theme.light"
        case .dark:
            return %"preferences.appearance.theme.dark"
        @unknown default:
            assertionFailure("Unregistered \(Self.self) enum value is not allowed: \(self)")
            return ""
        }
    }
}

private extension BackgroundService.Mode {
    var name: String {
        switch self {
        case .audio:
            return %"preferences.background.mode.audio"
        case .location:
            return %"preferences.background.mode.location"
        }
    }
}
