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

class PreferencesStorage {
    private init() {}
    private var disposeBag: [AnyCancellable] = []

    static let shared = PreferencesStorage()

    static let defaultTorrentListGroupsSortingArray: [TorrentHandle.State] = [
        .checkingFiles,
        .downloadingMetadata,
        .downloading,
        .finished,
        .seeding,
        .checkingResumeData,
        .paused
    ]

    @UserDefaultItem("torrentListSortType", .alphabetically) var torrentListSortType: TorrentListViewModel.Sort
    @UserDefaultItem("torrentListSortReverced", false) var torrentListSortReverced: Bool
    @UserDefaultItem("torrentListIsGroubedByState", false) var torrentListGroupedByState: Bool

    @UserDefaultItem("torrentListGroupsSortingArray", PreferencesStorage.defaultTorrentListGroupsSortingArray)
    var torrentListGroupsSortingArray: [TorrentHandle.State]

    @UserDefaultItem("preferencesAllocateMemory", false) var allocateMemory: Bool

    @UserDefaultItem("preferencesMaxActiveTorrents", 4) var maxActiveTorrents: Int
    @UserDefaultItem("preferencesMaxDownloadingTorrents", 3) var maxDownloadingTorrents: Int
    @UserDefaultItem("preferencesMaxUploadingTorrents", 3) var maxUploadingTorrents: Int

    @UserDefaultItem("preferencesMaxUploadSpeed", 0) var maxUploadSpeed: UInt
    @UserDefaultItem("preferencesMaxDownloadSpeed", 0) var maxDownloadSpeed: UInt

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

    var settingsUpdatePublisher: AnyPublisher<Void, Never> {
        Just<Void>(())
            .combineLatest($allocateMemory)
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
            .map { _ in }
            .eraseToAnyPublisher()
    }
}

extension Session.Settings {
    static func fromPreferences(with interfaces: [String]) -> Self {
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

        let interfacesToUse = [interfaces.first].compactMap { $0 }
        settings.outgoingInterfaces = interfacesToUse.joined(separator: ",")
        settings.listenInterfaces = interfacesToUse.map { "\($0):\(settings.port)" }.joined(separator: ",")

        print("--- \(settings.listenInterfaces)")

        return settings
    }
}
