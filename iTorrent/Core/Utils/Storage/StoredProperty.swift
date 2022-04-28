//
//  StoredProperty.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 28.04.2022.
//

import Foundation
import ReactiveKit

@propertyWrapper struct StoredProperty<T> where T: Codable {
    private let id: String
    private let bag = DisposeBag()
    private let value: Property<T>

    var wrappedValue: T {
        get { value.value }
        set { value.value = newValue }
    }

    var projectedValue: Property<T> { value }

    init(wrappedValue: T, id: String) {
        self.id = id
        self.value = Property<T>(wrappedValue)
        restore()
        bind()
    }

    func removeFromStorage() {
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: id)
    }
}

private extension StoredProperty {
    private func bind() {
        value.observeNext { value in save(value) }.dispose(in: bag)
    }

    private func save(_ value: T) {
        guard let encodedData = try? PropertyListEncoder().encode(value)
        else { return }

        let userDefaults = UserDefaults.standard
        userDefaults.set(encodedData, forKey: id)
    }

    private func restore() {
        guard let decoded = UserDefaults.standard.object(forKey: id) as? Data,
              let restore = try? PropertyListDecoder().decode(T.self, from: decoded)
        else { return }

        value.value = restore
    }
}
