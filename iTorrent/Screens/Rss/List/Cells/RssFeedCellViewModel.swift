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
        var rssModel: RssFeedSnapshot
        var selectAction: (() -> Void)?
    }
}

class RssFeedCellViewModel: BaseViewModelWith<RssFeedCellViewModel.Config>, MvvmSelectableProtocol, MvvmReorderableProtocol, @unchecked Sendable {
    var model: RssFeedSnapshot!
    var selectAction: (() -> Void)?
    var canReorder: Bool { true }

    @Published var feedLogo: UIImage? = nil
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var newCounter: Int = 0

    let popoverPreferenceNavigationTransaction = PassthroughRelay<(from: UIViewController, to: UIViewController)>()

    override func prepare(with model: Config) {
        self.model = model.rssModel
        title = model.rssModel.displayTitle
        description = model.rssModel.displayDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        newCounter = model.rssModel.updatesCount
        selectAction = model.selectAction

        feedLogo = .icRss
        if let linkImage = model.rssModel.linkImage {
            Task { @MainActor in
                feedLogo = await imageLoader.loadImage(from: linkImage)
            }
        }
    }

    override func hash(into hasher: inout Hasher) {
        hasher.combine(model)
    }

    func openPreferences() {
        Task { @MainActor in
#if !os(visionOS)
            let vc = RssListPreferencesViewModel(with: model).resolveVC()
            let nvc = UINavigationController(rootViewController: vc)
            navigationService?()?.navigate(to: nvc, by: .present(wrapInNavigation: false))
#else
            navigate(to: RssListPreferencesViewModel.self, with: model, by: .custom(transaction: { [weak self] from, to in
                self?.popoverPreferenceNavigationTransaction.send((from, to))
            }))
#endif
        }
    }

    @Injected private var imageLoader: ImageLoader
}
