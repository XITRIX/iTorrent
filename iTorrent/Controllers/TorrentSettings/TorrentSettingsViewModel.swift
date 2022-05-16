//
//  TorrentSettingsViewModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 14.05.2022.
//

import MVVMFoundation

class TorrentSettingsViewModel: MvvmViewModel {
    typealias Switch = TorrentSettingsSwitchViewModel

    private let preferences: PropertyStorage = MVVM.resolve()
    @Bindable var sections = [SectionModel<TableCellRepresentable>]()

    override func setup() {
        super.setup()

        title.value = "Preferences"

        // MARK: - Status Section
        let allocateStorage = Switch(title: "Allocate storage")

        bind(in: bag) {
            preferences.$preallocationStorage <=> allocateStorage.$value
        }

        sections.append(SectionModel<TableCellRepresentable>(header: "Storage", items: [allocateStorage]))
    }
}
