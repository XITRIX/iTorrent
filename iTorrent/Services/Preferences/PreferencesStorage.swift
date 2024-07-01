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
        #if !IS_SUPPORT_LOCATION_BG
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

    static let defaultTorrentListGroupsSortingArray: [TorrentHandle.State] = [
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
    @UserDefaultItem("torrentStorageScopes", [:]) var storageScopes: [UUID: StorageModel]

    @UserDefaultItem("torrentListSortType", .alphabetically) var torrentListSortType: TorrentListViewModel.Sort
    @UserDefaultItem("torrentListSortReverced", false) var torrentListSortReverced: Bool
    @UserDefaultItem("torrentListIsGroubedByState", false) var torrentListGroupedByState: Bool

    @UserDefaultItem("torrentListGroupsSortingArray", PreferencesStorage.defaultTorrentListGroupsSortingArray)
    var torrentListGroupsSortingArray: [TorrentHandle.State]

    @UserDefaultItem("preferencesAllocateMemory", false) var allocateMemory: Bool

    @UserDefaultItem("preferencesStopSeedingOnFinish", false) var stopSeedingOnFinish: Bool

    @UserDefaultItem("preferencesMaxActiveTorrents", 4) var maxActiveTorrents: Int
    @UserDefaultItem("preferencesMaxDownloadingTorrents", 3) var maxDownloadingTorrents: Int
    @UserDefaultItem("preferencesMaxUploadingTorrents", 3) var maxUploadingTorrents: Int

    @UserDefaultItem("preferencesMaxUploadSpeed", 0) var maxUploadSpeed: UInt
    @UserDefaultItem("preferencesMaxDownloadSpeed", 0) var maxDownloadSpeed: UInt

    @UserDefaultItem("preferencesIsCellularEnabled", false) var isCellularEnabled: Bool
    @UserDefaultItem("preferencesUseAllAvailableInterfaces", false) var useAllAvailableInterfaces: Bool

    @UserDefaultItem("preferencesConnectionDht", true) var isDhtEnabled: Bool
    @UserDefaultItem("preferencesConnectionLsd", true) var isLsdEnabled: Bool
    @UserDefaultItem("preferencesConnectionUtp", true) var isUtpEnabled: Bool
    @UserDefaultItem("preferencesConnectionUpnp", true) var isUpnpEnabled: Bool
    @UserDefaultItem("preferencesConnectionNatPmp", true) var isNatEnabled: Bool

    @UserDefaultItem("preferencesEncryptionPolicy", .enabled) var encryptionPolicy: Session.Settings.EncryptionPolicy

    @UserDefaultItem("preferencesUseDefaultPort", true) var useDefaultPort: Bool
    @UserDefaultItem("preferencesPort", 6881) var port: Int
    @UserDefaultItem("preferencesPortBindRetries", 10) var portBindRetries: Int

    @UserDefaultItem("preferencesProxyType", .none) var proxyType: Session.Settings.ProxyType
    @UserDefaultItem("preferencesProxyHostname", "") var proxyHostname: String
    @UserDefaultItem("preferencesProxyHostPort", 8080) var proxyHostPort: Int
    @UserDefaultItem("preferencesProxyAuthRequired", false) var proxyAuthRequired: Bool
    @UserDefaultItem("preferencesProxyUsername", "") var proxyUsername: String
    @UserDefaultItem("preferencesProxyPassword", "") var proxyPassword: String
    @UserDefaultItem("preferencesProxyPeerConnections", true) var proxyPeerConnections: Bool

    @UserDefaultItem("preferencesApplicationAppearance", .unspecified) var appAppearance: UIUserInterfaceStyle
    @NSUserDefaultItem("preferencesTintColor", .accent) var tintColor: UIColor

    @UserDefaultItem("preferencesNotificationsDownload", true) var isDownloadNotificationsEnabled: Bool
    @UserDefaultItem("preferencesNotificationsSeed", true) var isSeedNotificationsEnabled: Bool

    @UserDefaultItem("preferencesBackgroundDownloadEnabled", true) var isBackgroundDownloadEnabled: Bool
    @UserDefaultItem("preferencesBackgroundMode", .audio) var backgroundMode: BackgroundService.Mode
    @UserDefaultItem("preferencesBackgroundAllowSeeding", false) var isBackgroundSeedingEnabled: Bool
    @UserDefaultItem("preferencesBackgroundLocationIndicator", false) var isBackgroundLocationIndicatorEnabled: Bool

    @UserDefaultItem("preferencesIsFileSharingEnabled", false) var isFileSharingEnabled: Bool
    @UserDefaultItem("preferencesIsWebServerEnabled", false) var isWebServerEnabled: Bool
    @UserDefaultItem("preferencesIsWebDavServerEnabled", false) var isWebDavServerEnabled: Bool
    @UserDefaultItem("preferencesWebServerPort", 80) var webServerPort: Int
    @UserDefaultItem("preferencesWebDavServerPort", 81) var webDavServerPort: Int
    @UserDefaultItem("preferencesWebServerLogin", "") var webServerLogin: String
    @UserDefaultItem("preferencesWebServerPassword", "") var webServerPassword: String

    @UserDefaultItem("preferencesPatreonAccount", nil) var patreonAccount: PatreonAccount?
    @UserDefaultItem("preferencesPatreonToken", nil) var patreonToken: PatreonToken?
    @UserDefaultItem("preferencesPatreonCredentials", nil) var patreonCredentials: PatreonCredentials?

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
            .map { _ in }
            .eraseToAnyPublisher()
    }
}

extension Session.Settings {
    static func fromPreferences(with interfaces: [NWInterface]) -> Self {
        let settings = Self()
        let preferences = PreferencesStorage.shared

        settings.maxActiveTorrents = preferences.maxActiveTorrents
        settings.maxDownloadingTorrents = preferences.maxDownloadingTorrents
        settings.maxUploadingTorrents = preferences.maxUploadingTorrents

        settings.maxUploadSpeed = preferences.maxUploadSpeed
        settings.maxDownloadSpeed = preferences.maxDownloadSpeed

        settings.isDhtEnabled = preferences.isDhtEnabled
        settings.isLsdEnabled = preferences.isLsdEnabled
        settings.isUtpEnabled = preferences.isUtpEnabled
        settings.isUpnpEnabled = preferences.isUpnpEnabled
        settings.isNatEnabled = preferences.isNatEnabled

        settings.encryptionPolicy = preferences.encryptionPolicy

        settings.useDefaultPort = preferences.useDefaultPort
        settings.port = preferences.port
        settings.portBindRetries = preferences.portBindRetries

        var interfacesToUse = interfaces
        if !preferences.useAllAvailableInterfaces {
            interfacesToUse = [interfacesToUse.first].compactMap { $0 }
        }
        let interfacesNamesToUse = interfacesToUse.map { $0.name } + ["lo0"]
        settings.outgoingInterfaces = interfacesNamesToUse.joined(separator: ",")
        settings.listenInterfaces = interfacesNamesToUse.map { "\($0):\(settings.port)" }.joined(separator: ",")

        print("--- \(settings.listenInterfaces)")

        return settings
    }
}
