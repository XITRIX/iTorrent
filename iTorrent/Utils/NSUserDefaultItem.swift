//
//  NSUserDefault.swift
//  ReManga
//
//  Created by Даниил Виноградов on 01.06.2023.
//

import Combine
import Foundation
import MvvmFoundation

@propertyWrapper
struct NSUserDefaultItem<Value: NSObject & NSCoding> {
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

private extension NSUserDefaultItem {
    static var userDefaults: UserDefaults { .itorrentGroup }

    static func value(for key: String) -> Value? {
        guard let data = userDefaults.data(forKey: key)
        else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: Value.self, from: data)
    }

    static func setValue(_ value: Value, for key: String) {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: true)
            userDefaults.set(data, forKey: key)
        } catch {}
    }
}
