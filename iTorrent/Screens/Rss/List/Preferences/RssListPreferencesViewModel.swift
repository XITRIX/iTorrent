//
//  RssListPreferencesViewModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 10.04.2024.
//

import MvvmFoundation
import Combine
import UIKit

class RssListPreferencesViewModel: BaseCollectionViewModelWith<RssModel> {
    override func prepare(with model: RssModel) {
        var sections: [MvvmCollectionSectionModel] = []
        defer { self.sections = sections }

        sections.append(.init(id: "prefs", style: .plain) {
            PRButtonViewModel(with: .init(title: %"rsslist.preference.url", value: Just(model.xmlLink.absoluteString).eraseToAnyPublisher(), tinted: false, singleLine: true, selectAction: { [unowned self] in
                UIPasteboard.general.string = model.xmlLink.absoluteString
                alertWithTimer(title: %"rsslist.preference.urlCopy")
                dismissSelection.send()
            }))
            PRButtonViewModel(with: .init(title: %"rsslist.preference.name", value: model.displayTitle, singleLine: true, selectAction: { [unowned self] in
                textInput(title: %"rsslist.preference.name", placeholder: model.title, defaultValue: model.customTitle) { [unowned self] res in
                    dismissSelection.send()
                    guard let res else { return }
                    model.customTitle = res
                }
            }))
            PRButtonViewModel(with: .init(title: %"rsslist.preference.description", value: model.displayDescription, singleLine: true, selectAction: { [unowned self] in
                textInput(title: %"rsslist.preference.description", placeholder: model.description, defaultValue: model.customDescription) { [unowned self] res in
                    dismissSelection.send()
                    guard let res else { return }
                    model.customDescription = res
                }
            }))
            PRSwitchViewModel(with: .init(title: %"rsslist.preference.notifications", value: .init(get: {
                !model.muteNotifications
            }, set: { value in
                model.muteNotifications = !value
            })))
        })
    }
}
