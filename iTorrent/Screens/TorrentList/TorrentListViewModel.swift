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
    enum Sort: CaseIterable {
        case alphabetically
        case creationDate
        case size
    }
}

class TorrentListViewModel: BaseViewModel {
    @Published var sections: [MvvmCollectionSectionModel] = []
    @Published var searchQuery: String = ""
    @Published var title: String = ""
    @Published var sortingType: Sort = .alphabetically
    @Published var sortingReverced: Bool = false

    required init() {
        super.init()
        title = "iTorrent"

        TorrentService.shared.$torrents
            .combineLatest($searchQuery, $sortingType, $sortingReverced) { torrentHandles, searchQuery, sortingType, sortingReverced in
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

private extension Array where Element == TorrentHandle {
    func sorted(by type: TorrentListViewModel.Sort, reverced: Bool) -> [Element] {
        let res = sorted { first, second in
            switch type {
            case .alphabetically:
                return first.name.localizedCaseInsensitiveCompare(second.name) == .orderedAscending
            case .creationDate:
                return first.creationDate ?? Date() > second.creationDate ?? Date()
            case .size:
                return first.totalWanted > second.totalWanted
            }
        }

        return reverced ? res.reversed() : res
    }
}
