//
//  TorrentHandle+LocalStorage.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 28.04.2022.
//

import Bond
import Foundation
import ReactiveKit
import TorrentKit

extension TorrentHandle {
    struct LocalStorage: Codable {
        var addedDate: Date
        var allowSeeding: Bool

        enum CodingKeys: String, CodingKey {
            case addedDate
            case allowSeeding
        }

        init(addedDate: Date = Date(),
             allowSeeding: Bool = false)
        {
            self.addedDate = addedDate
            self.allowSeeding = allowSeeding
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            addedDate = (try? container.decode(Date.self, forKey: .addedDate)) ?? Date()
            allowSeeding = (try? container.decode(Bool.self, forKey: .allowSeeding)) ?? false
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(addedDate, forKey: .addedDate)
            try container.encode(allowSeeding, forKey: .allowSeeding)
        }
    }

    fileprivate enum AssociatedKeys {
        static var LocalStorageObserver = "AssociatedKeyLocalStorageObserver"
    }

    func initLocalStorage() {
        localStorage = StoredProperty<LocalStorage>.init(wrappedValue: LocalStorage(), id: infoHash.hex)
    }

    func removeLocalStorage() {
        localStorage.removeFromStorage()
    }

    fileprivate var localStorage: StoredProperty<LocalStorage> {
        get {
            guard let subject = objc_getAssociatedObject(self, &AssociatedKeys.LocalStorageObserver) as? StoredProperty<LocalStorage>
            else { fatalError("\(Self.self) - localStorage is not initialized") }

            return subject
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.LocalStorageObserver, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }

    var addedDate: Date {
        get { localStorage.wrappedValue.addedDate }
        set { localStorage.wrappedValue.addedDate = newValue }
    }

    var allowSeeding: Bool {
        get { localStorage.wrappedValue.allowSeeding }
        set {
            localStorage.wrappedValue.allowSeeding = newValue
            rx.updateObserver.send(self)
        }
    }
}

extension ReactiveExtensions where Base == TorrentHandle {
    var addedDate: DynamicSubject<Date> {
        dynamicSubject(
            signal: base.localStorage.projectedValue.eraseType(),
            get: { $0.addedDate },
            set: { $0.addedDate = $1 })
    }

    var allowSeeding: DynamicSubject<Bool> {
        dynamicSubject(
            signal: base.localStorage.projectedValue.eraseType(),
            get: { $0.allowSeeding },
            set: { $0.allowSeeding = $1 })
    }
}
