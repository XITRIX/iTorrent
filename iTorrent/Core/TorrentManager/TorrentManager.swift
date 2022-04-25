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

    @Bindable var torrents: [String: TorrentHandle] = [:]

    init() {
        rootFolder = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        downloadFolder = rootFolder + "/Downloads"
        torrentsFolder = rootFolder + "/torrents"
        fastResumesFolder = torrentsFolder + "/resume_data"

        session = Session(downloadFolder, torrentsPath: torrentsFolder, fastResumePath: fastResumesFolder)
        session.add(self)
    }

    func addTorrent(_ torrent: Downloadable) {
        session.addTorrent(torrent)
    }
}

private extension TorrentManager {
    func append(torrent: TorrentHandle) {
        autoreleasepool {
            guard let localTorrent = torrents[torrent.infoHash] else {
                DispatchQueue.main.async { [self] in
                    torrents[torrent.infoHash] = torrent
                }
                return
            }

            localTorrent.rx.update()
        }
    }
}

extension TorrentManager: SessionDelegate {
    func torrentManager(_ manager: Session, didAddTorrent torrent: TorrentHandle) {
        append(torrent: torrent)
    }

    func torrentManager(_ manager: Session, didRemoveTorrentWithHash hashData: Data) {}

    func torrentManager(_ manager: Session, didReceiveUpdateForTorrent torrent: TorrentHandle) {
        append(torrent: torrent)
    }

    func torrentManager(_ manager: Session, didErrorOccur error: Error) {}
}
