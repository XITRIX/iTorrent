//
//  StorageModel+Extensions.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 05/07/2024.
//

import LibTorrent

extension StorageModel {
    static var defaultName: String { "iTorrent Default" }
}

extension Optional where Wrapped: StorageModel {
    var name: String {
        switch self {
        case .none:
            return StorageModel.defaultName
        case .some(let wrapped):
            return wrapped.name
        }
    }
}
