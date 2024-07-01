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
    private let disposeBag = DisposeBag()

    let projectedValue: CurrentValueSubject<T, Never>

    var wrappedValue: T {
        get { projectedValue.value }
        set { projectedValue.value = newValue }
    }

    init(_ key: String, _ defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
        projectedValue = CurrentValueSubject(Self.get(by: key) ?? defaultValue)

        disposeBag.bind {
            projectedValue.sink { value in
                Self.set(by: key, value)
            }
        }
    }
}

private extension UserDefaultItem {
    static var userDefaults: UserDefaults { .itorrentGroup }

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
