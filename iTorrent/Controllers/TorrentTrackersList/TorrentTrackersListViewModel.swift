//
//  TorrentTrackersListViewModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 02.05.2022.
//

import Foundation
import MVVMFoundation
import TorrentKit

class TorrentTrackersListViewModel: MvvmViewModelWith<TorrentHandle> {
    private var torrent: TorrentHandle!

    @Bindable var sections = [SectionModel<TorrentTrackerModel>]()

    override func prepare(with item: MvvmViewModelWith<TorrentHandle>.Model) {
        self.torrent = item
        configure()
    }

    override func setup() {
        super.setup()
        
        title.value = "Trackers"
    }

    func configure() {
        bind(in: bag) {
            torrent.rx.updateObserver.map { torrent -> [SectionModel<TorrentTrackerModel>] in
                [SectionModel(items: torrent.trackers.map { TorrentTrackerModel(with: $0) } )]
            } => $sections
        }
    }

    func addTracker(url: String) {
        torrent.addTracker(url)
        torrent.rx.update()
    }

    func removeTrackers(at indexes: [Int]) {
        let urls = indexes.compactMap { sections.first?.$items.value[$0].url }
        torrent.removeTrackers(urls)
        torrent.rx.update()
    }
}
