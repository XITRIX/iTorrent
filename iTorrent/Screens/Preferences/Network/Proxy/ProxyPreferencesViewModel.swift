//
//  ProxyPreferencesViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 02/04/2024.
//

import MvvmFoundation

class ProxyPreferencesViewModel: BasePreferencesViewModel {
    required init() {
        super.init()
        reload()
    }

    private let preferences = PreferencesStorage.shared
}

private extension ProxyPreferencesViewModel {
    func reload() {
        title.send(%"preferences.network.proxy")
        
        var sections: [MvvmCollectionSectionModel] = []
        defer { self.sections.send(sections) }

    }
}
