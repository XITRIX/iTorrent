//
//  TorrentsListTorrentModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 22.04.2022.
//

import MVVMFoundation
import ReactiveKit
import TorrentKit

struct TorrentsListTorrentModel {
    let torrent: TorrentHandle

    var title: SafeSignal<String> {
        torrent.rx.name
    }

    var progressText: SafeSignal<String> {
        torrent.rx.updateObserver.map { $0.progressDescription }
    }

    var statusText: SafeSignal<String> {
        torrent.rx.updateObserver.map { $0.statusDescription }
    }

    var progress: SafeSignal<Float> {
        torrent.rx.progress
    }
}

extension TorrentsListTorrentModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(torrent.infoHash)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
//        false
        return lhs.torrent == rhs.torrent
    }
}

private extension TorrentHandle {
    var progressDescription: String {
        let percentString = String(format: "%0.2f%%", progress * 100)
        let totalWantedString = Utils.Size.getSizeText(size: totalWanted)
        let totalWantedDoneString = Utils.Size.getSizeText(size: totalWantedDone)

        return "\(totalWantedDoneString) of \(totalWantedString) (\(percentString))"
    }

    var statusDescription: String {
        switch displayState {
        case .downloading:
            let timeRemains = Utils.Time.downloadingTimeRemainText(speedInBytes: Int64(downloadRate), fileSize: Int64(totalWanted), downloadedSize: Int64(totalWantedDone))
            return "\(displayState) - \(displayState.symbol)\(Utils.Size.getSizeText(size: downloadRate)) - time remains: \(timeRemains)"
        case .seeding:
            return "\(displayState) - \(displayState.symbol)\(Utils.Size.getSizeText(size: uploadRate))"
        default:
            return displayState.description
        }
    }
}
