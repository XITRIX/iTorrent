//
//  TorrentsListTorrentModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 22.04.2022.
//

import MVVMFoundation
import TorrentKit

struct TorrentsListTorrentModel {
    let torrent: TorrentHandle
    @Bindable var title: String?
    @Bindable var progressText: String?
    @Bindable var statusText: String?
    @Bindable var progress: Float = 0
}

extension TorrentsListTorrentModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(torrent.infoHash)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.title == rhs.title else { return false }
        guard lhs.progressText == rhs.progressText else { return false }
        guard lhs.statusText == rhs.statusText else { return false }
        guard lhs.progress == rhs.progress else { return false }
        
        return true
    }
}
