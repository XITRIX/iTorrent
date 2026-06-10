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

class TorrentListItemViewModel: BaseViewModelWith<TorrentSession.Handle>, MvvmSelectableProtocol, ObservableObject, Identifiable {
    var torrentHandle: TorrentSession.Handle!
    var selectAction: (() -> Void)?
    var id: TorrentSession.Hashes { torrentHandle.infoHashes }

    @Published var title: String = ""
    @Published var progressText: String = ""
    @Published var statusText: String = ""
    @Published var progress: Double = 0

    override func prepare(with model: TorrentSession.Handle) {
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

    var snapshot: TorrentSession.Handle.Snapshot {
        guard let snapshot = torrentHandle.currentSnapshot else {
            fatalError("Snapshot should exist for active torrent handle")
        }
        return snapshot
    }

    func removeTorrent() {
        let snapshot = snapshot

        alert(title: %"torrent.remove.title", message: snapshot.name, actions: [
            .init(title: %"torrent.remove.action.dropData", style: .destructive, action: {
                TorrentService.shared.removeTorrent(by: snapshot.infoHashes, deleteFiles: true)
            }),
            .init(title: %"torrent.remove.action.keepData", style: .default, action: {
                TorrentService.shared.removeTorrent(by: snapshot.infoHashes, deleteFiles: false)
            }),
            .init(title: %"common.cancel", style: .cancel, isPrimary: true)
        ])
    }
}

private extension TorrentListItemViewModel {
    func updateUI() {
        let snapshot = snapshot
        let percent = "\(String(format: "%.2f", snapshot.progress * 100))%"
        title = snapshot.name
        progressText = %"\(snapshot.totalWantedDone.bitrateToHumanReadable) of \(snapshot.totalWanted.bitrateToHumanReadable) (\(percent))"
        statusText = "\(snapshot.stateText)"
        progress = snapshot.progress
    }
}
