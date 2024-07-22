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
        disposeBag.bind {
            model.rssModel.displayTitle.sink { [unowned self] text in
                title = text
            }
            model.rssModel.displayDescription.sink { [unowned self] text in
                description = text.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            model.rssModel.updatesCount.sink { [unowned self] num in
                newCounter = num
            }
        }

        selectAction = model.selectAction

        feedLogo = .icRss
        if let linkImage = model.rssModel.linkImage {
            Task {
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
