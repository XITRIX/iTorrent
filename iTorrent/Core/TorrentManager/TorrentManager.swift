//
//  TorrentManager.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 25.04.2022.
//

import Bond
import Foundation
import MVVMFoundation
import ReactiveKit
import TorrentKit

class TorrentManager {
    let rootFolder: String
    let downloadFolder: String
    let torrentsFolder: String
    let fastResumesFolder: String

    let session: Session

    @Bindable var torrents: [Data: TorrentHandle] = [:]

    init() {
        rootFolder = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        downloadFolder = rootFolder + "/Downloads"
        torrentsFolder = rootFolder + "/torrents"
        fastResumesFolder = torrentsFolder + "/resume_data"

        session = Session(downloadFolder, torrentsPath: torrentsFolder, fastResumePath: fastResumesFolder)
        session.add(self)

        torrents = Dictionary(uniqueKeysWithValues: session.torrents.map { ($0.infoHash, $0) })
    }

    func addTorrent(_ torrent: Downloadable) {
        session.addTorrent(torrent)
    }

    func removeTorrent(_ torrent: TorrentHandle, deleteFiles: Bool) {
        session.removeTorrent(torrent, deleteFiles: deleteFiles)
    }
}

private extension TorrentManager {
    func append(torrent: TorrentHandle) {
        autoreleasepool {
            DispatchQueue.main.async { [self] in
                if torrents[torrent.infoHash] == nil {
                    torrents[torrent.infoHash] = torrent
                }
            }
        }
    }

    func update(torrent: TorrentHandle) {
        autoreleasepool {
            guard let localTorrent = torrents[torrent.infoHash]
            else { return }

            localTorrent.rx.update()
        }
    }

    func remove(by hash: Data) {
        autoreleasepool {
            DispatchQueue.main.async { [self] in
                torrents.removeValue(forKey: hash)
            }
        }
    }
}

extension TorrentManager: SessionDelegate {
    func torrentManager(_ manager: Session, didAddTorrent torrent: TorrentHandle) {
        append(torrent: torrent)
    }

    func torrentManager(_ manager: Session, didRemoveTorrentWithHash hashData: Data) {
        remove(by: hashData)
    }

    func torrentManager(_ manager: Session, didReceiveUpdateForTorrent torrent: TorrentHandle) {
        update(torrent: torrent)
    }

    func torrentManager(_ manager: Session, didErrorOccur error: Error) {}
}
