//
//  UserPreferences.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 30/08/2019.
//  Copyright © 2019  XITRIX. All rights reserved.
//

import Foundation

class UserPreferences {
    static var background = SettingProperty<Bool>("backgroundKey", true)
    static let backgroundSeedKey = SettingProperty<Bool>("backgroundSeedKey", false)
    static let notificationsKey = SettingProperty<Bool>("notificationsKey", true)
    static let notificationsSeedKey = SettingProperty<Bool>("notificationsSeedKey", true)
    static let badgeKey = SettingProperty<Bool>("badgeKey", true)
    static let ftpKey = SettingProperty<Bool>("ftpKey", false)
    static let ftpBackgroundKey = SettingProperty<Bool>("ftpBackgroundKey", false)
    static let sectionsSortingOrder = SettingProperty<[Int]>("sectionsSortingOrder", [3,7,8,6,2,4,5,9,1])
    static let themeNum = SettingProperty<Int>("themeNum", 0)
    static let downloadLimit = SettingProperty<Int64>("downloadLimit", 0)
    static let uploadLimit = SettingProperty<Int64>("uploadLimit", 0)
    static let seedBackgroundWarning = SettingProperty<Bool>("seedBackgroundWarning", false)
    static let disableAds = SettingProperty<Bool>("disableAds", false)
    
    static let sortingType = SettingProperty<Int>("SortingType", 0)
    static let sortingSections = SettingProperty<Bool>("SortingSections", true)
    
    
    private static let localVersion = (try? String(contentsOf: Bundle.main.url(forResource: "Version", withExtension: "ver")!)) ?? ""
    static let versionNews = SettingProperty<Bool>("versionNews" + localVersion, false)
    
    class SettingProperty<T> {
        let key : String
        let defaultValue : T
        var value : T {
            get { return UserDefaults.standard.value(forKey: key) as? T ?? defaultValue }
            set { UserDefaults.standard.set(newValue, forKey: key) }
        }
        
        init(_ key: String, _ defaultValue: T) {
            self.key = key
            self.defaultValue = defaultValue
        }
    }
}