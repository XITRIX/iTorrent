//
//  RssListPreferencesViewModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 10.04.2024.
//

import MvvmFoundation
import Combine

class RssListPreferencesViewModel: BaseCollectionViewModelWith<Void> {
    override func prepare(with model: Void) {
        var sections: [MvvmCollectionSectionModel] = []
        defer { self.sections = sections }

        sections.append(.init(id: "prefs") {
            PRButtonViewModel(with: .init(title: "URL", value: Just("Title").eraseToAnyPublisher(), selectAction: {

            }))
            PRButtonViewModel(with: .init(title: "Название", value: Just("Title").eraseToAnyPublisher(), selectAction: {

            }))
            PRButtonViewModel(with: .init(title: "Описание", value: Just("Title").eraseToAnyPublisher(), selectAction: {

            }))
            PRSwitchViewModel(with: .init(title: "Оповещение", value: .constant(true)))
        })
    }
}
