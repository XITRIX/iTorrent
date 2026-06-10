//
//  RssListPreferencesViewModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 10.04.2024.
//

import Combine
import MvvmFoundation
import UIKit

class RssListPreferencesViewModel: BaseCollectionViewModelWith<RssFeedSnapshot> {
    override func prepare(with model: RssFeedSnapshot) {
        var sections: [MvvmCollectionSectionModel] = []
        defer { self.sections = sections }

        sections.append(.init(id: "prefs", style: .plain) {
            PRButtonViewModel(with: .init(title: %"rsslist.preference.url", value: Just(model.xmlLink.absoluteString).eraseToAnyPublisher(), tinted: false, singleLine: true, selectAction: { [unowned self] in
                UIPasteboard.general.string = model.xmlLink.absoluteString
                alertWithTimer(title: %"rsslist.preference.urlCopy")
                dismissSelection.send()
            }))
            PRButtonViewModel(with: .init(title: %"rsslist.preference.name", value: Just(model.displayTitle).eraseToAnyPublisher(), singleLine: true, selectAction: { [unowned self] in
                textInput(title: %"rsslist.preference.name", placeholder: model.title, defaultValue: model.customTitle) { [unowned self] res in
                    dismissSelection.send()
                    guard let res else { return }
                    Task { [rssProvider] in
                        await rssProvider.updatePreferences(id: model.id, customTitle: res, customDescription: nil, muteNotifications: nil)
                    }
                }
            }))
            PRButtonViewModel(with: .init(title: %"rsslist.preference.description", value: Just(model.displayDescription).eraseToAnyPublisher(), singleLine: true, selectAction: { [unowned self] in
                textInput(title: %"rsslist.preference.description", placeholder: model.description, defaultValue: model.customDescription) { [unowned self] res in
                    dismissSelection.send()
                    guard let res else { return }
                    Task { [rssProvider] in
                        await rssProvider.updatePreferences(id: model.id, customTitle: nil, customDescription: res, muteNotifications: nil)
                    }
                }
            }))
            PRSwitchViewModel(with: .init(title: %"rsslist.preference.notifications", value: .init(get: {
                !model.muteNotifications
            }, set: { [rssProvider] value in
                Task {
                    await rssProvider.updatePreferences(id: model.id, customTitle: nil, customDescription: nil, muteNotifications: !value)
                }
            })))
        })
    }

    @Injected private var rssProvider: RssFeedProvider
}
