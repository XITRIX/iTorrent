//
//  TorrentService.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 29/10/2023.
//

import Combine
import Foundation
import LibTorrent

class TorrentService {
    @Published var torrents: [TorrentHandle] = []

    static let shared = TorrentService()

    init() { session.add(self) }

    static var downloadPath: URL { try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) }
    static var torrentPath: URL { downloadPath.appending(path: "config") }
    static var fastResumePath: URL { downloadPath.appending(path: "config") }
    static var metadataPath: URL { downloadPath.appending(path: "config") }

    private let session: Session = {
        var settings = Session.Settings()
        print("Working directory: \(downloadPath.path())")
        return .init(downloadPath.path(), torrentsPath: torrentPath.path(), fastResumePath: fastResumePath.path(), settings: settings)
    }()
}

extension TorrentService {
    func addTorrent(by file: Downloadable) {
        guard !torrents.contains(where: { file.infoHashes == $0.infoHashes })
        else { return }

        session.addTorrent(file)
    }

    func addTorrent(by path: URL) {
        defer { path.stopAccessingSecurityScopedResource() }
        guard path.startAccessingSecurityScopedResource(),
              let file = TorrentFile(with: path)
        else { return }

        guard !torrents.contains(where: { file.infoHashes == $0.infoHashes })
        else { return }

        session.addTorrent(file)
    }

    func removeTorrent(by infoHashes: TorrentHashes, deleteFiles: Bool) {
        guard let handle = torrents.first(where: { $0.infoHashes == infoHashes })
        else { return }

        handle.deleteMetadata()
        session.removeTorrent(handle, deleteFiles: deleteFiles)
    }
}

extension TorrentService: SessionDelegate {
    func torrentManager(_ manager: Session, didAddTorrent torrent: TorrentHandle) {
        DispatchQueue.main.sync { [self] in
            _ = torrent.metadata
            torrents.append(torrent)
        }
    }

    func torrentManager(_ manager: Session, didRemoveTorrentWithHash hashesData: TorrentHashes) {
        // Already on Main thread
        torrents.removeAll(where: { $0.infoHashes == hashesData })
    }

    func torrentManager(_ manager: Session, didReceiveUpdateForTorrent torrent: TorrentHandle) {
        guard let existingTorrent = torrents.first(where: { $0.hashValue == torrent.hashValue })
        else { return }

        DispatchQueue.main.sync {
            existingTorrent.updatePublisher.send(existingTorrent)
        }
    }

    func torrentManager(_ manager: Session, didErrorOccur error: Error) {}
}

private var TorrentHandleUpdatePublisherKey: UInt8 = 0
extension TorrentHandle {
    var updatePublisher: PassthroughSubject<TorrentHandle, Never> {
        guard let obj = objc_getAssociatedObject(self, &TorrentHandleUpdatePublisherKey) as? PassthroughSubject<TorrentHandle, Never>
        else {
            objc_setAssociatedObject(self, &TorrentHandleUpdatePublisherKey, PassthroughSubject<TorrentHandle, Never>(), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            return objc_getAssociatedObject(self, &TorrentHandleUpdatePublisherKey) as! PassthroughSubject<TorrentHandle, Never>
        }
        return obj
    }
}
