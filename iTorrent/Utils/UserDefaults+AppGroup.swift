//
//  UserDefaults+AppGroup.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 30.06.2024.
//

import Foundation

extension UserDefaults {
    static var itorrentGroup: UserDefaults {
        UserDefaults(suiteName: "group.itorrent.life-activity") ?? .standard
    }
}
