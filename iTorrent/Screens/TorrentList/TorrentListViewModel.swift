//
//  TorrentListViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 29/10/2023.
//

import LibTorrent
import MvvmFoundation

class TorrentListViewModel: BaseViewModel {
    @Published var sections: [MvvmCollectionSectionModel] = []
    @Published var searchQuery: String = ""
    @Published var title: String = ""

    override func binding() {
        title = "iTorrent"
        
        TorrentService.shared.$torrents.combineLatest($searchQuery) { torrentHandles, searchQuery in
            if searchQuery.isEmpty { return torrentHandles }
            return torrentHandles.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
        }
        .map { [unowned self] torrents in
            [.init(id: "torrents", style: .plain, showsSeparators: true, items: torrents.map {
                let vm = TorrentListItemViewModel(with: $0)
                vm.navigationService = navigationService
                return vm
            } )]
        }
        .assign(to: &$sections)
    }
}
