//
//  TorrentHandle+Extension.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 31/10/2023.
//

import LibTorrent

extension TorrentHandle {
    var friendlyState: State {
        switch state {
        case .downloading:
            if isPaused { return .paused }
            else { return .downloading }
        case .finished:
            if isPaused { return .finished }
            else { return .seeding }
        case .seeding:
            if isPaused { return .finished }
            else { return .seeding }
        default:
            return state
        }
    }
}

extension TorrentHandle.State {
    var name: String {
        switch self {
        case .checkingFiles:
            return "Prepairing"
        case .downloadingMetadata:
            return "Fetching metadata"
        case .downloading:
            return "Downloading"
        case .finished:
            return "Done"
        case .seeding:
            return "Seeding"
        case .checkingResumeData:
            return "Resuming"
        case .paused:
            return "Paused"
        @unknown default:
            return ""
        }
    }
}

extension TorrentHandle {
    struct Metadata: Codable {
        var dateAdded: Date = Date()
    }

    var metadata: Metadata {
        let hash = infoHashes.best.hex
        let url = TorrentService.metadataPath.appendingPathComponent("\(hash).tmeta", isDirectory: false)
        if FileManager.default.fileExists(atPath: url.path()),
           let data = try? Data(contentsOf: url),
           let meta = try? JSONDecoder().decode(Metadata.self, from: data)
        {
            return meta
        }

        let meta = Metadata()
        if let data = try? JSONEncoder().encode(meta) {
            try? data.write(to: url)
        }

        return meta
    }

    func deleteMetadata() {
        let hash = infoHashes.best.hex
        let url = TorrentService.metadataPath.appendingPathComponent("\(hash).tmeta", isDirectory: false)
        try? FileManager.default.removeItem(at: url)
    }
}
