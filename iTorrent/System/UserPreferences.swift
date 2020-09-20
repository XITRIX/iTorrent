//
//  UserPreferences.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 30/08/2019.
//  Copyright © 2019  XITRIX. All rights reserved.
//

import ITorrentFramework
import UIKit

class UserPreferences {
    @PreferenceItem("backgroundKey", true) static var background: Bool
    @PreferenceItem("backgroundSeedKey", false) static var backgroundSeedKey: Bool
    @PreferenceItem("notificationsKey", true) static var notificationsKey: Bool
    @PreferenceItem("notificationsSeedKey", true) static var notificationsSeedKey: Bool
    @PreferenceItem("badgeKey", true) static var badgeKey: Bool
    @PreferenceItem("ftpKey", false) static var ftpKey: Bool
    @PreferenceItem("ftpBackgroundKey", false) static var ftpBackgroundKey: Bool
    @PreferenceItem("ftpWebKey", false) static var ftpWebKey: Bool
    @PreferenceItem("ftpWebDavKey", false) static var ftpWebDavKey: Bool
    @PreferenceItem("webDavUsername", "") static var webDavUsername: String
    @PreferenceItem("webDavPassword", "") static var webDavPassword: String
    @PreferenceItem("webDavWebServerEnabled", true) static var webServerEnabled: Bool
    @PreferenceItem("webDavWebDavServerEnabled", false) static var webDavServerEnabled: Bool
    @PreferenceItem("webDavPort", 81) static var webDavPort: Int
    @PreferenceItem("sectionsSortingOrder", [3, 7, 8, 6, 2, 4, 5, 9, 1]) static var sectionsSortingOrder: [Int]
    @PreferenceItem("themeNum", 0) static var themeNum: Int
    @PreferenceItem("zeroSpeedLimit", 60) static var zeroSpeedLimit: Int
    @PreferenceItem("downloadLimit", 0) static var downloadLimit: Int
    @PreferenceItem("uploadLimit", 0) static var uploadLimit: Int
    @PreferenceItem("seedBackgroundWarning", false) static var seedBackgroundWarning: Bool
    @PreferenceItem("storagePreallocation", false) static var storagePreallocation: Bool

    @PreferenceItem("SortingType", 0) static var sortingType: Int
    @PreferenceItem("SortingSections2", false) static var sortingSections: Bool
    
    //network
    @PreferenceItem("enableDht", true) static var enableDht: Bool
    @PreferenceItem("enableLsd", true) static var enableLsd: Bool
    @PreferenceItem("enableUtp", true) static var enableUtp: Bool
    @PreferenceItem("enableUpnp", true) static var enableUpnp: Bool
    @PreferenceItem("enableNatpmp", true) static var enableNatpmp: Bool
    
    @PreferenceItem("onlyVpn", false) static var onlyVpn: Bool
    @PreferenceItem("interface", "") static var interface: String
    
    @PreferenceItem("defaultPort", true) static var defaultPort: Bool
    @PreferenceItem("portRangeFirst", 6881) static var portRangeFirst: Int
    @PreferenceItem("portRangeSecond", 6891) static var portRangeSecond: Int
    
    //proxy
    @PreferenceData("proxyType", ProxyType.none) static var proxyType: ProxyType!
    @PreferenceItem("proxyRequiresAuth", false) static var proxyRequiresAuth: Bool
    @PreferenceItem("proxyHostname", "") static var proxyHostname: String
    @PreferenceItem("proxyPort", 8080) static var proxyPort: Int
    @PreferenceItem("proxyUsername", "") static var proxyUsername: String
    @PreferenceItem("proxyPassword", "") static var proxyPassword: String
    @PreferenceItem("proxyPeerConnections", true) static var proxyPeerConnections: Bool

    @PreferenceItem("autoTheme", true, { value in
        if #available(iOS 13, *) {
            return value
        }
        return false
    }) static var autoTheme: Bool

    private static let localVersion = (try? String(contentsOf: Bundle.main.url(forResource: "Version", withExtension: "ver")!)) ?? ""
    @PreferenceItem("versionNews" + localVersion, false) static var versionNews: Bool

    /// Patreon
    @PreferenceData("patreonAccessToken", "") static var patreonAccessToken: String?
    @PreferenceData("patreonRefreshToken", "") static var patreonRefreshToken: String?
    
    @PreferenceData("patreonAccount", nil) static var patreonAccount: PatreonAccount?
    @PreferenceData("patreonCredentials", nil) static var patreonCredentials: PatreonCredentials?
    
    static func alertDialog(code: String) -> SettingProperty<Bool> {
        SettingProperty<Bool>("alertDialog" + code, false)
    }
    
    static var disableAds: Bool {
        UserPreferences.patreonAccount?.hideAds ?? false
    }
}

class SettingProperty<T> {
    let key: String
    let defaultValue: T
    let calculatedValue: ((T) -> (T))?
    var value: T {
        get {
            let res = UserDefaults.standard.value(forKey: key) as? T ?? defaultValue
            return calculatedValue?(res) ?? res
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
    
    init(_ key: String, _ defaultValue: T, calculatedValue: ((T) -> (T))? = nil) {
        self.key = key
        self.defaultValue = defaultValue
        self.calculatedValue = calculatedValue
    }
}

@propertyWrapper
struct PreferenceItem<T> {
    let key: String
    let defaultValue: T
    let calculatedValue: ((T) -> (T))?

    var wrappedValue: T {
        get {
            let res = UserDefaults.standard.value(forKey: key) as? T ?? defaultValue
            return calculatedValue?(res) ?? res
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }

    init(_ key: String, _ defaultValue: T, _ calculatedValue: ((T) -> (T))? = nil) {
        self.key = key
        self.defaultValue = defaultValue
        self.calculatedValue = calculatedValue
    }
}

@propertyWrapper
struct PreferenceData<T: Codable> {
    let key: String
    let defaultValue: T
    let calculatedValue: ((T) -> (T))?

    var wrappedValue: T {
        get {
            guard let decoded = UserDefaults.standard.data(forKey: key)
            else { return defaultValue }

            let decoder = JSONDecoder()
            guard let res = try? decoder.decode(T.self, from: decoded)
            else { return defaultValue }
            
            return calculatedValue?(res) ?? res
        }
        set {
            let userDefaults = UserDefaults.standard
            let encoder = JSONEncoder()

            if let encodedData: Data = try? encoder.encode(newValue) {
                userDefaults.set(encodedData, forKey: key)
            } else {
                userDefaults.set(nil, forKey: key)
            }
        }
    }

    init(_ key: String, _ defaultValue: T, calculatedValue: ((T) -> (T))? = nil) {
        self.key = key
        self.defaultValue = defaultValue
        self.calculatedValue = calculatedValue
    }
}
