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
    private var torrentHandle: TorrentHandle!
//    @Published var updater: Bool = false
    var selectAction: (() -> Void)?
    var id: Int { hashValue }

    @Published var title: String = ""
    @Published var progressText: String = ""
    @Published var statusText: String = ""
    @Published var progress: Double = 0

    override func prepare(with model: TorrentHandle) {
        torrentHandle = model
        updateUI()

        disposeBag.bind {
            torrentHandle.updatePublisher
                .receive(on: DispatchQueue.global(qos: .userInitiated))
                .sink { [weak self] _ in
                    self?.updateUI()
                }
        }

        selectAction = { [unowned self] in
            navigate(to: TorrentDetailsViewModel.self, with: model, by: .detail(asRoot: true))
        }
    }

    override func hash(into hasher: inout Hasher) {
        hasher.combine(torrentHandle)
    }

    func removeTorrent() {
        alert(title: "Are you sure to remove", message: torrentHandle.name, actions: [
            .init(title: "Yes and remove data", style: .destructive, action: { [unowned self] in
                TorrentService.shared.removeTorrent(by: torrentHandle.infoHashes, deleteFiles: true)
            }),
            .init(title: "Yes but keep data", style: .default, action: { [unowned self] in
                TorrentService.shared.removeTorrent(by: torrentHandle.infoHashes, deleteFiles: false)
            }),
            .init(title: "Cancel", style: .cancel)
        ])
    }
}

private extension TorrentListItemViewModel {
    func updateUI() {
        guard torrentHandle.isValid else { return }

        let percent = "\(String(format: "%.2f", torrentHandle.progress * 100))%"
        let title = torrentHandle.name
        let progressText = "\(torrentHandle.totalWantedDone.bitrateToHumanReadable) of \(torrentHandle.totalWanted.bitrateToHumanReadable) (\(percent))"
        let statusText = "\(torrentHandle.stateText)"
        let progress = torrentHandle.progress

        Task {
            self.title = title
            self.progressText = progressText
            self.statusText = statusText
            self.progress = progress
        }
    }
}

private extension TorrentHandle {
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
