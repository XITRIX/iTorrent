//
//  Cache.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 26.10.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import Foundation

class Cache<Key : Hashable, Value> {
    private var wrapped = NSCache<WrappedKey, Entry>()
}

private extension Cache {
    final class WrappedKey: NSObject {
        let key: Key

        init(_ key: Key) { self.key = key }

        override var hash: Int { return key.hashValue }

        override func isEqual(_ object: Any?) -> Bool {
            guard let value = object as? WrappedKey
            else { return false }

            return value.key == key
        }
    }
    
    subscript(key: Key) -> Value? {
        get {
            let entry = wrapped.object(forKey: WrappedKey(key))
            return entry?.value
        }
        set {
            if let value = newValue {
                let entry = Entry(value: value)
                wrapped.setObject(entry, forKey: WrappedKey(key))
            } else {
                wrapped.removeObject(forKey: WrappedKey(key))
            }
        }
    }
}

private extension Cache {
    final class Entry {
        let value: Value

        init(value: Value) {
            self.value = value
        }
    }
}
