//
//  UserPreferences.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 30/08/2019.
//  Copyright © 2019  XITRIX. All rights reserved.
//

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
    @PreferenceItem("webDavWebServerEnabled", true) static var webDavWebServerEnabled: Bool
    @PreferenceItem("webDavWebDavServerEnabled", false) static var webDavWebDavServerEnabled: Bool
    @PreferenceItem("webDavPort", 81) static var webDavPort: Int
    @PreferenceItem("sectionsSortingOrder", [3, 7, 8, 6, 2, 4, 5, 9, 1]) static var sectionsSortingOrder: [Int]
    @PreferenceItem("themeNum", 0) static var themeNum: Int
    @PreferenceItem("zeroSpeedLimit", 60) static var zeroSpeedLimit: Int
    @PreferenceItem("downloadLimit", 0) static var downloadLimit: Int64
    @PreferenceItem("uploadLimit", 0) static var uploadLimit: Int64 
    @PreferenceItem("seedBackgroundWarning", false) static var seedBackgroundWarning: Bool
    @PreferenceItem("storagePreallocation", false) static var storagePreallocation: Bool

    @PreferenceItem("SortingType", 0) static var sortingType: Int
    @PreferenceItem("SortingSections", true) static var sortingSections: Bool

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
    
    @PreferenceData("patreonAccount") static var patreonAccount: PatreonAccount?
    @PreferenceData("patreonCredentials") static var patreonCredentials: PatreonCredentials?
    
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
    let defaultValue: T?
    let calculatedValue: ((T) -> (T))?

    var wrappedValue: T? {
        get {
            guard let decoded = UserDefaults.standard.data(forKey: key)
            else { return nil }

            let decoder = JSONDecoder()
            guard let res = try? decoder.decode(T.self, from: decoded)
            else { return nil }
            
            return calculatedValue?(res) ?? res
        }
        set {
            let userDefaults = UserDefaults.standard
            let encoder = JSONEncoder()

            if let newValue = newValue,
                let encodedData: Data = try? encoder.encode(newValue) {
                userDefaults.set(encodedData, forKey: key)
            } else {
                userDefaults.set(nil, forKey: key)
            }
        }
    }

    init(_ key: String, _ defaultValue: T? = nil, calculatedValue: ((T) -> (T))? = nil) {
        self.key = key
        self.defaultValue = defaultValue
        self.calculatedValue = calculatedValue
    }
}
