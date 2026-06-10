//
//  StorageModel+Extensions.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 05/07/2024.
//

import LibTorrent

extension TorrentSession.Storage {
    static var defaultName: String { "iTorrent Default" }

    @discardableResult
    mutating func resolveSequrityScopes() -> Bool {
        do {
            var isStale = false

            url = try URL(resolvingBookmarkData: pathBookmark, bookmarkDataIsStale: &isStale)
            resolved = true

            allowed = url.startAccessingSecurityScopedResource()
            defer { url.stopAccessingSecurityScopedResource() }
            print("Path - \(url) | write permissions - \(allowed)")

            if isStale {
                pathBookmark = try url.bookmarkData(options: [.minimalBookmark])
            }

            return allowed
        } catch {
            allowed = false
            resolved = false
            print(error)
            return false
        }
    }
}

extension Optional where Wrapped == TorrentSession.Storage {
    var name: String {
        switch self {
        case .none:
            return TorrentSession.Storage.defaultName
        case .some(let wrapped):
            return wrapped.name
        }
    }
}
