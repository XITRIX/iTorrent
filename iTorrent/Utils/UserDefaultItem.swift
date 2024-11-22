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
struct UserDefaultItem<Value: Codable> {
    private let key: String
    private let disposeBag = DisposeBag()

    let projectedValue: CurrentValueSubject<Value, Never>

    var wrappedValue: Value {
        get { projectedValue.value }
        set { projectedValue.value = newValue }
    }

    init(_ key: String, _ defaultValue: Value) {
        self.key = key

        let loadedValue = Self.value(for: key)
        if loadedValue == nil {
            Self.setValue(defaultValue, for: key)
        }

        projectedValue = .init(Self.value(for: key) ?? defaultValue)

        disposeBag.bind {
            projectedValue.sink { value in
                Self.setValue(value, for: key)
            }
        }
    }
}

private extension UserDefaultItem {
    static var userDefaults: UserDefaults { .itorrentGroup }

    static func value(for key: String) -> Value? {
        guard let data = userDefaults.data(forKey: key)
        else { return nil }
        return try? JSONDecoder().decode(Value.self, from: data)
    }

    static func setValue(_ value: Value?, for key: String) {
        if let value, let data: Data = try? JSONEncoder().encode(value) {
            userDefaults.set(data, forKey: key)
        } else {
            userDefaults.set(nil, forKey: key)
        }
    }
}
