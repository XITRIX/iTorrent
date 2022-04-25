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
}

extension TorrentsListViewModel {
    func mapTorrentsIntoSections(_ torrents: Property<[String: TorrentHandle]>) -> Signal<[SectionModel<TorrentsListTorrentModel>], Never> {
        torrents.map { [unowned self] dict in
            var section = SectionModel<TorrentsListTorrentModel>()
            section.items = dict.values.sorted(by: sortTorrents).map { torrent in
                let item = TorrentsListTorrentModel(torrent: torrent)
                bind(in: torrent.bag) {
                    torrent.rx.name => item.$title
                    torrent.rx.progress => item.$progress
                    torrent.rx.updateObserver.map { $0.progressDescription } => item.$progressText
                    torrent.rx.updateObserver.map { $0.statusDescription } => item.$statusText
                }
                return item
            }
            return [section]
        }
    }

    func sortTorrents(_ lhs: TorrentHandle, _ rhs: TorrentHandle) -> Bool {
        lhs.name < rhs.name
    }
}

private extension TorrentHandle {
    var progressDescription: String {
        let percentString = String(format: "%0.2f%%", progress * 100)
        let totalWantedString = ByteCountFormatter.string(fromByteCount: Int64(totalWanted), countStyle: .binary)
        let totalWantedDoneString = ByteCountFormatter.string(fromByteCount: Int64(totalWantedDone), countStyle: .binary)

        return "\(totalWantedDoneString) of \(totalWantedString) (\(percentString))"
    }

    var statusDescription: String {
        let progressString = String(format: "%0.2f %%", progress * 100)
        return "\(state.symbol) \(state), \(progressString), seeds: \(numberOfSeeds), peers: \(numberOfPeers)"
    }
}
