//
//  TorrentListItemViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 29/10/2023.
//

import Combine
import LibTorrent
import MvvmFoundation
import SwiftUI

class TorrentListItemViewModel: BaseViewModelWith<TorrentHandle>, MvvmSelectableProtocol, ObservableObject, Identifiable {
    var torrentHandle: TorrentHandle!
    var selectAction: (() -> Void)?
    var id: ObjectIdentifier { .init(torrentHandle) }

    @Published var title: String = ""
    @Published var progressText: String = ""
    @Published var statusText: String = ""
    @Published var progress: Double = 0

    override func prepare(with model: TorrentHandle) {
        torrentHandle = model
        updateUI()

        disposeBag.bind {
            torrentHandle.updatePublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.updateUI()
                }
        }

        selectAction = { [unowned self] in
            navigate(to: TorrentDetailsViewModel.self, with: model, by: .detail(asRoot: true))
        }
    }

    override func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    func removeTorrent() {
        alert(title: %"torrent.remove.title", message: torrentHandle.snapshot.name, actions: [
            .init(title: %"torrent.remove.action.dropData", style: .destructive, action: { [unowned self] in
                TorrentService.shared.removeTorrent(by: torrentHandle.snapshot.infoHashes, deleteFiles: true)
            }),
            .init(title: %"torrent.remove.action.keepData", style: .default, action: { [unowned self] in
                TorrentService.shared.removeTorrent(by: torrentHandle.snapshot.infoHashes, deleteFiles: false)
            }),
            .init(title: %"common.cancel", style: .cancel)
        ])
    }
}

private extension TorrentListItemViewModel {
    func updateUI() {
        let percent = "\(String(format: "%.2f", torrentHandle.snapshot.progress * 100))%"
        title = torrentHandle.snapshot.name
        progressText = "\(torrentHandle.snapshot.totalWantedDone.bitrateToHumanReadable) of \(torrentHandle.snapshot.totalWanted.bitrateToHumanReadable) (\(percent))"
        statusText = "\(torrentHandle.snapshot.stateText)"
        progress = torrentHandle.snapshot.progress
    }
}

private extension TorrentHandle.Snapshot {
    var stateText: String {
        let state = friendlyState
        var text = "\(state.name)"

        if state == .downloading {
            text += " - ↓ \(downloadRate.bitrateToHumanReadable)/s"
            text += " - \(timeRemains)"
        }

        return text
    }
}
