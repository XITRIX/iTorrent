//
//  TorrentTrackersViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 10/11/2023.
//

import LibTorrent
import MvvmFoundation

class TorrentTrackersViewModel: BaseViewModelWith<TorrentHandle> {
    private var torrentHandle: TorrentHandle!

    @Published var sections: [MvvmCollectionSectionModel] = []

    override func prepare(with model: TorrentHandle) {
        torrentHandle = model
        reload()
    }
}

private extension TorrentTrackersViewModel {
    func reload() {
        var sections: [MvvmCollectionSectionModel] = []
        defer { self.sections = sections }

        sections.append(.init(id: "trackers", style: .plain, items:
            torrentHandle.trackers.map { tracker in
                TrackerCellViewModel(with: tracker)
            }))
    }
}
