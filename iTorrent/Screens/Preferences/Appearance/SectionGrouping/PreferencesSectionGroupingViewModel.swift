//
//  PreferencesSectionGroupingViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 04/04/2024.
//

import MvvmFoundation
import LibTorrent

class PreferencesSectionGroupingViewModel: BasePreferencesViewModel {
    required init() {
        super.init()
        reload()
    }

    private let preferences = PreferencesStorage.shared
}

extension PreferencesSectionGroupingViewModel {
    func resetAction() {
        preferences.torrentListGroupsSortingArray = PreferencesStorage.defaultTorrentListGroupsSortingArray
        reload()
    }

    func didMoved(with snapshot: MvvmCollectionViewDataSource.Snapshot) {
        let items = snapshot.itemIdentifiers(inSection: snapshot.sectionIdentifiers[0])
            .compactMap { $0.viewModel as? PRButtonViewModel }
            .compactMap { $0.metadata as? TorrentHandle.State }

        preferences.torrentListGroupsSortingArray = items
    }
}

private extension PreferencesSectionGroupingViewModel {
    func reload() {
        title.send(%"preferences.appearance.order")

        var sections: [MvvmCollectionSectionModel] = []
        defer { self.sections.send(sections) }

        sections.append(.init(id: "order", items: preferences.torrentListGroupsSortingArray.map { stateType in
            let model = PRButtonViewModel(with: .init(title: stateType.name, canReorder: true, accessories: [.reorder()]))
            model.metadata = stateType
            return model
        }))
    }
}
