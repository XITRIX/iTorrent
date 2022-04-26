//
//  TorrentsListViewModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 28.03.2022.
//

import MVVMFoundation
import ReactiveKit
import TorrentKit

class TorrentsListViewModel: MvvmViewModel {
    private let torrentManager = MVVM.resolve() as TorrentManager
    @Bindable public var sections = [SectionModel<TorrentsListTorrentModel>]()

    required init() {
        super.init()
        title.value = "iTorrent"
    }

    override func binding() {
        bind(in: bag) {
            mapTorrentsIntoSections(torrentManager.$torrents) => $sections
        }
    }

    func openTorrentDetails(at indexPath: IndexPath) {
        navigate(to: TorrentDetailsViewModel.self, prepare: sections[indexPath.section].items[indexPath.row].torrent)
    }

    func addTorrentFile(with url: URL) {
        if url.startAccessingSecurityScopedResource() {
            let file = TorrentFile(fileAt: url)
            url.stopAccessingSecurityScopedResource()
            navigate(to: TorrentAddingViewModel.self, prepare: TorrentAddingModel(file: file), with: .modal(wrapInNavigation: true))
        }
    }

    func addMagnet(with link: String) {
        guard let url = URL(string: link) else { return }
        torrentManager.addTorrent(MagnetURI(magnetURI: url))
    }

    func removeTorrent(at index: IndexPath, deleteFiles: Bool) {
        let torrent = sections[index.section].items[index.row].torrent
        torrentManager.removeTorrent(torrent, deleteFiles: deleteFiles)
    }
}

extension TorrentsListViewModel {
    func mapTorrentsIntoSections(_ torrents: Property<[Data: TorrentHandle]>) -> Signal<[SectionModel<TorrentsListTorrentModel>], Never> {
        return torrents.map { [unowned self] dict in
            var section = SectionModel<TorrentsListTorrentModel>()
            section.items = dict.values.sorted(by: sortTorrents).map { torrent in
                TorrentsListTorrentModel(torrent: torrent)
            }
            return [section]
        }
    }

    func sortTorrents(_ lhs: TorrentHandle, _ rhs: TorrentHandle) -> Bool {
        lhs.name < rhs.name
    }
}
