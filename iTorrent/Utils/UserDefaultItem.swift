//
//  UserDefaultItem.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 07/11/2023.
//

import Combine
import Foundation
import MvvmFoundation

@propertyWrapper
struct UserDefaultItem<T: Codable> {
    private let key: String
    private let defaultValue: T
    private let value: CurrentValueSubject<T, Never>
    private let disposeBag = DisposeBag()

    var wrappedValue: T {
        get { value.value }
        set { value.value = newValue }
    }

    var projectedValue: CurrentValueSubject<T, Never> {
        value
    }

    init(_ key: String, _ defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
        value = CurrentValueSubject(Self.get(by: key) ?? defaultValue)

        disposeBag.bind {
            value.sink { value in
                Self.set(by: key, value)
            }
        }
    }
}

private extension UserDefaultItem {
    static var userDefaults: UserDefaults { UserDefaults(suiteName: "group.itorrent.life-activity") ?? .standard }

    static func get(by key: String) -> T? {
        guard let decoded = userDefaults.data(forKey: key),
              let res = try? JSONDecoder().decode(T.self, from: decoded)
        else { return nil }
        return res
    }

    static func set(by key: String, _ value: T?) {
        if let value, let encodedData: Data = try? JSONEncoder().encode(value) {
            userDefaults.set(encodedData, forKey: key)
        } else {
            userDefaults.set(nil, forKey: key)
        }
    }
}
