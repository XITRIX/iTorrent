//
//  TorrentListViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 29/10/2023.
//

import LibTorrent
import MvvmFoundation
import SwiftData

extension TorrentListViewModel {
    enum Sort: CaseIterable, Codable {
        case alphabetically
        case creationDate
        case addedDate
        case size
    }
}

class TorrentListViewModel: BaseViewModel {
    @Published var sections: [MvvmCollectionSectionModel] = []
    @Published var searchQuery: String = ""
    @Published var title: String = ""

    var sortingType: CurrentValueRelay<Sort> {
        PreferencesStorage.shared.$torrentListSortType
    }

    var sortingReverced: CurrentValueRelay<Bool> {
        PreferencesStorage.shared.$torrentListSortReverced
    }

    required init() {
        super.init()
        title = "iTorrent"

        TorrentService.shared.$torrents
            .combineLatest($searchQuery, sortingType, sortingReverced) { torrentHandles, searchQuery, sortingType, sortingReverced in
                if searchQuery.isEmpty { return torrentHandles.sorted(by: sortingType, reverced: sortingReverced) }
                return torrentHandles.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }.sorted(by: sortingType, reverced: sortingReverced)
            }
            .map { [unowned self] torrents in
                [.init(id: "torrents", style: .plain, showsSeparators: true, items: torrents.map {
                    let vm = TorrentListItemViewModel(with: $0)
                    vm.navigationService = navigationService
                    return vm
                })]
            }
            .assign(to: &$sections)
    }
}

extension TorrentListViewModel {
    func preferencesAction() {
        navigate(to: PreferencesViewModel.self, by: .show)
    }

    func addTorrent(by url: URL) {
        defer { url.stopAccessingSecurityScopedResource() }
        guard url.startAccessingSecurityScopedResource(),
              let file = TorrentFile(with: url)
        else { return }

        guard !TorrentService.shared.torrents.contains(where: { $0.infoHashes == file.infoHashes })
        else {
            alert(title: "This torrent already exists", message: "Torrent with hash:\n\"\(file.infoHashes.best.hex)\" already exists in download queue", actions: [.init(title: "Close", style: .cancel)])
            return
        }

        navigate(to: TorrentAddViewModel.self, with: .init(torrentFile: file), by: .present(wrapInNavigation: true))
    }
}

private extension Array where Element == TorrentHandle {
    func sorted(by type: TorrentListViewModel.Sort, reverced: Bool) -> [Element] {
        let res = filter(\.isValid).sorted { first, second in
            switch type {
            case .alphabetically:
                return first.name.localizedCaseInsensitiveCompare(second.name) == .orderedAscending
            case .creationDate:
                return first.creationDate ?? Date() > second.creationDate ?? Date()
            case .addedDate:
                return first.metadata.dateAdded > second.metadata.dateAdded
            case .size:
                return first.totalWanted > second.totalWanted
            }
        }

        return reverced ? res.reversed() : res
    }
}
