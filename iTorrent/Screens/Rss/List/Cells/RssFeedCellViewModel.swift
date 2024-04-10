//
//  RssFeedCellViewModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 08.04.2024.
//

import MvvmFoundation
import UIKit

extension RssFeedCellViewModel {
    struct Config {
        var rssModel: RssModel
        var selectAction: (() -> Void)?
    }
}

class RssFeedCellViewModel: BaseViewModelWith<RssFeedCellViewModel.Config>, MvvmSelectableProtocol, MvvmReorderableProtocol {
    var model: RssModel!
    var selectAction: (() -> Void)?
    var canReorder: Bool { true }

    @Published var feedLogo: UIImage? = nil
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var newCounter: Int = 0

    let popoverPreferenceNavigationTransaction = PassthroughRelay<(from: UIViewController, to: UIViewController)>()

    override func prepare(with model: Config) {
        self.model = model.rssModel
        feedLogo = .icRss // TODO: Add real icon
        model.rssModel.$title.assign(to: &$title)
        model.rssModel.$description.map { $0 ?? "" }.assign(to: &$description)
        model.rssModel.updatesCount.assign(to: &$newCounter)

        selectAction = model.selectAction
    }

    override func hash(into hasher: inout Hasher) {
        hasher.combine(model)
    }

    func openPreferences() {
//        navigate(to: RssListPreferencesViewModel.self, with: (), by: .present(wrapInNavigation: true))

        navigate(to: RssListPreferencesViewModel.self, with: (), by: .custom(transaction: { [weak self] from, to in
            self?.popoverPreferenceNavigationTransaction.send((from, to))
        }))
    }
}
