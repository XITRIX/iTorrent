//
//  PreferencesStorage.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 07/11/2023.
//

import Combine
import Foundation
import LibTorrent
import MvvmFoundation
import UIKit
import Network

class PreferencesStorage: Resolvable {
    private init() {
        #if !IS_SUPPORT_LOCATION_BG && !os(tvOS)
        // Location mode is not allowed by Apple policy
        backgroundMode = .audio
        #endif

        // Sanity check for defaultStorage if something went wrong
        if defaultStorage != nil, !storageScopes.contains(where: { $0.key == defaultStorage }) { defaultStorage = nil }

        // Fix sorting array in case new status appeared
        if torrentListGroupsSortingArray.count != Self.defaultTorrentListGroupsSortingArray.count {
            torrentListGroupsSortingArray = Self.defaultTorrentListGroupsSortingArray
        }

        // TODO: REMOVE LATER!!!
        isStorageRulesAccepted = false


    }

    private var disposeBag: [AnyCancellable] = []
    static let shared = PreferencesStorage()

    static let defaultTorrentListGroupsSortingArray: [TorrentSession.Handle.State] = [
        .checkingFiles,
        .downloadingMetadata,
        .downloading,
        .seeding,
        .finished,
        .checkingResumeData,
        .paused,
        .storageError
    ]

    @UserDefaultItem("torrentDefaultStorage", nil) var defaultStorage: UUID?
    @UserDefaultItem("torrentIsStorageRulesAccepted", false) var isStorageRulesAccepted: Bool
    @UserDefaultItem("torrentStorageScopes", [:]) var storageScopes: [UUID: TorrentSession.Storage]

    #if !os(tvOS)
    @UserDefaultItem("torrentListSortType", .alphabetically) var torrentListSortType: TorrentListViewModel.Sort
    #endif
    @UserDefaultItem("torrentListSortReverced", false) var torrentListSortReverced: Bool
    @UserDefaultItem("torrentListIsGroubedByState", false) var torrentListGroupedByState: Bool

    @UserDefaultItem("torrentListGroupsSortingArray", PreferencesStorage.defaultTorrentListGroupsSortingArray)
    var torrentListGroupsSortingArray: [TorrentSession.Handle.State]

    @UserDefaultItem("preferencesAllocateMemory", false) var allocateMemory: Bool

    @UserDefaultItem("preferencesStopSeedingOnFinish", false) var stopSeedingOnFinish: Bool

    @UserDefaultItem("preferencesMaxActiveTorrents", 4) var maxActiveTorrents: Int
    @UserDefaultItem("preferencesMaxDownloadingTorrents", 3) var maxDownloadingTorrents: Int
    @UserDefaultItem("preferencesMaxUploadingTorrents", 3) var maxUploadingTorrents: Int

    @UserDefaultItem("preferencesMaxUploadSpeed", 0) var maxUploadSpeed: UInt
    @UserDefaultItem("preferencesMaxDownloadSpeed", 0) var maxDownloadSpeed: UInt

    @UserDefaultItem("preferencesTrackersAutoaddingEnabled", false) var isTrackersAutoaddingEnabled: Bool

    @UserDefaultItem("preferencesIsCellularEnabled", false) var isCellularEnabled: Bool
    @UserDefaultItem("preferencesUseAllAvailableInterfaces", false) var useAllAvailableInterfaces: Bool

    @UserDefaultItem("preferencesConnectionDht", true) var isDhtEnabled: Bool
    @UserDefaultItem("preferencesConnectionLsd", true) var isLsdEnabled: Bool
    @UserDefaultItem("preferencesConnectionUtp", true) var isUtpEnabled: Bool
    @UserDefaultItem("preferencesConnectionUpnp", true) var isUpnpEnabled: Bool
    @UserDefaultItem("preferencesConnectionNatPmp", true) var isNatEnabled: Bool

    @UserDefaultItem("preferencesEncryptionPolicy", .enabled) var encryptionPolicy: TorrentSession.Configuration.EncryptionPolicy
    @UserDefaultItem("preferencesValidateHttpsTrackers", true) var validateHttpsTrackers: Bool


    @UserDefaultItem("preferencesUseDefaultPort", true) var useDefaultPort: Bool
    @UserDefaultItem("preferencesPort", 6881) var port: Int
    @UserDefaultItem("preferencesPortBindRetries", 10) var portBindRetries: Int

    @UserDefaultItem("preferencesProxyType", .none) var proxyType: TorrentSession.Configuration.ProxyType
    @UserDefaultItem("preferencesProxyHostname", "") var proxyHostname: String
    @UserDefaultItem("preferencesProxyHostPort", 8080) var proxyHostPort: Int
    @UserDefaultItem("preferencesProxyAuthRequired", false) var proxyAuthRequired: Bool
    @UserDefaultItem("preferencesProxyUsername", "") var proxyUsername: String
    @UserDefaultItem("preferencesProxyPassword", "") var proxyPassword: String
    @UserDefaultItem("preferencesProxyPeerConnections", true) var proxyPeerConnections: Bool

    #if !os(tvOS)
    @UserDefaultItem("preferencesApplicationAppearance", .unspecified) var appAppearance: UIUserInterfaceStyle
    @NSUserDefaultItem("preferencesTintColor", .accent) var tintColor: UIColor
    #endif

    @UserDefaultItem("preferencesNotificationsDownload", true) var isDownloadNotificationsEnabled: Bool
    @UserDefaultItem("preferencesNotificationsSeed", true) var isSeedNotificationsEnabled: Bool

    #if !os(tvOS)
    @UserDefaultItem("preferencesBackgroundDownloadEnabled", true) var isBackgroundDownloadEnabled: Bool
    @UserDefaultItem("preferencesBackgroundMode", .audio) var backgroundMode: BackgroundService.Mode
    @UserDefaultItem("preferencesBackgroundAllowSeeding", false) var isBackgroundSeedingEnabled: Bool
    @UserDefaultItem("preferencesBackgroundLocationIndicator", false) var isBackgroundLocationIndicatorEnabled: Bool
    #endif

    @UserDefaultItem("preferencesIsFileSharingEnabled", false) var isFileSharingEnabled: Bool
    @UserDefaultItem("preferencesIsWebServerEnabled", false) var isWebServerEnabled: Bool
    @UserDefaultItem("preferencesIsWebDavServerEnabled", false) var isWebDavServerEnabled: Bool
    @UserDefaultItem("preferencesWebServerPort", 80) var webServerPort: Int
    @UserDefaultItem("preferencesWebDavServerPort", 81) var webDavServerPort: Int
    @UserDefaultItem("preferencesWebServerLogin", "") var webServerLogin: String
    @UserDefaultItem("preferencesWebServerPassword", "") var webServerPassword: String

    #if !os(tvOS)
    @UserDefaultItem("preferencesPatreonAccount", nil) var patreonAccount: PatreonAccount?
    @UserDefaultItem("preferencesPatreonToken", nil) var patreonToken: PatreonToken?
    @UserDefaultItem("preferencesPatreonCredentials", nil) var patreonCredentials: PatreonCredentials?
    #endif

    @UserDefaultItem("initialSetupCellularPassed", false) var initialSetupCellularPassed: Bool

    var settingsUpdatePublisher: AnyPublisher<Void, Never> {
        Just<Void>(())
            .combineLatest($maxActiveTorrents)
            .combineLatest($maxDownloadingTorrents)
            .combineLatest($maxUploadingTorrents)
            .combineLatest($maxUploadSpeed)
            .combineLatest($maxDownloadSpeed)
            .combineLatest($isDhtEnabled)
            .combineLatest($isLsdEnabled)
            .combineLatest($isUtpEnabled)
            .combineLatest($isUpnpEnabled)
            .combineLatest($isNatEnabled)
            .combineLatest($encryptionPolicy)
            .combineLatest($validateHttpsTrackers)
            .combineLatest($useDefaultPort)
            .combineLatest($port)
            .combineLatest($portBindRetries)
            .combineLatest($proxyType)
            .combineLatest($proxyHostname)
            .combineLatest($proxyHostPort)
            .combineLatest($proxyAuthRequired)
            .combineLatest($proxyUsername)
            .combineLatest($proxyPassword)
            .combineLatest($proxyPeerConnections)
            .combineLatest($useAllAvailableInterfaces)
            .map { _ in /* ignore result */ }
            .eraseToAnyPublisher()
    }
}

extension TorrentSession.Configuration {
    static func fromPreferences(with interfaces: [NWInterface]) -> Self {
        let preferences = PreferencesStorage.shared

        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let appBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"

        var port = 6881
        if !preferences.useDefaultPort {
            port = preferences.port
        }

        var interfacesToUse = interfaces
        if !preferences.useAllAvailableInterfaces {
            interfacesToUse = [interfacesToUse.first].compactMap { $0 }
        }
        let interfacesNamesToUse = interfacesToUse.map { $0.name } + ["lo0"]
        let outgoingInterfaces = interfacesNamesToUse.joined(separator: ",")
        let listenInterfaces = interfacesNamesToUse.map { "\($0):\(port)" }.joined(separator: ",")

        print("--- \(listenInterfaces)")

        return Self(
            agentName: "iTorrent: v\(appVersion)-\(appBuild)",
            preallocateStorage: preferences.allocateMemory,
            maxActiveTorrents: preferences.maxActiveTorrents,
            maxDownloadingTorrents: preferences.maxDownloadingTorrents,
            maxUploadingTorrents: preferences.maxUploadingTorrents,
            maxDownloadSpeed: preferences.maxDownloadSpeed,
            maxUploadSpeed: preferences.maxUploadSpeed,
            isDhtEnabled: preferences.isDhtEnabled,
            isLsdEnabled: preferences.isLsdEnabled,
            isUtpEnabled: preferences.isUtpEnabled,
            isUpnpEnabled: preferences.isUpnpEnabled,
            isNatEnabled: preferences.isNatEnabled,
            encryptionPolicy: preferences.encryptionPolicy,
            validateHttpsTrackers: preferences.validateHttpsTrackers,
            port: port,
            portBindRetries: preferences.portBindRetries,
            outgoingInterfaces: outgoingInterfaces,
            listenInterfaces: listenInterfaces,
            proxyType: preferences.proxyType,
            proxyHostname: preferences.proxyHostname,
            proxyHostPort: preferences.proxyHostPort,
            proxyAuthRequired: preferences.proxyAuthRequired,
            proxyUsername: preferences.proxyUsername,
            proxyPassword: preferences.proxyPassword,
            proxyPeerConnections: preferences.proxyPeerConnections
        )
    }
}
