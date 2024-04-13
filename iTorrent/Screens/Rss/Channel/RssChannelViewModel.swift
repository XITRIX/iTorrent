//
//  RssChannelViewModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 08.04.2024.
//

import Combine
import MvvmFoundation
import UIKit

class RssChannelViewModel: BaseCollectionViewModelWith<RssModel> {
    @Published var title: String = ""
    var model: RssModel!

    var items: [RssChannelItemCellViewModel] = []

    override func prepare(with model: RssModel) {
        self.model = model
        disposeBag.bind {
            model.displayTitle.sink { [unowned self] text in
                title = text
            }
            model.$items.sink { [unowned self] models in
                reload(with: models)
            }
        }

        trailingSwipeActionsConfigurationProvider = { [unowned self] indexPath in
            let readed = model.items[indexPath.item].readed
            let action = UIContextualAction(style: .normal, title: readed ? %"rsschannel.unseen" : %"rsschannel.seen", handler: { [unowned self] _, _, completion in
                setSeen(!readed, for: indexPath.item)
                completion(true)
            })
//            action.image = readed ? .init(systemName: "eye.slash") : .init(systemName: "eye")
            action.backgroundColor = PreferencesStorage.shared.tintColor
            return .init(actions: [action])
        }
    }

    func readAll() {
        ignoreReloadRequests = true
        for index in 0 ..< model.items.count {
//            model.items[index].readed = true // Questionable, not sure it should be flaged as well
            model.items[index].new = false
        }
        rssFeedProvider.saveState()
        ignoreReloadRequests = false
        reload(with: model.items)
    }

    func setSeen(_ seen: Bool, for itemModel: RssItemModel) {
        guard let index = model.items.firstIndex(where: { $0 == itemModel })
        else { return }

        model.items[index].readed = seen
        model.items[index].new = false
        rssFeedProvider.saveState()
    }

    private var ignoreReloadRequests: Bool = false
    @Injected private var rssFeedProvider: RssFeedProvider
}

private extension RssChannelViewModel {
    func reload(with models: [RssItemModel]) {
        guard !ignoreReloadRequests else { return }

        var sections: [MvvmCollectionSectionModel] = []
        defer { self.sections = sections }

        items = models.enumerated().map { model in
            let vm: RssChannelItemCellViewModel
            if let existing = items.first(where: { $0.model == model.element }) {
                vm = existing
            } else {
                vm = RssChannelItemCellViewModel()
            }

            vm.prepare(with: .init(rssModel: model.element, selectAction: { [unowned self] in
                setSeen(true, for: model.offset)
                navigate(to: RssDetailsViewModel.self, with: model.element, by: .detail(asRoot: true))
            }))

            return vm
        }.removingDuplicates()

        sections.append(.init(id: "rss", style: .plain, items: items))
    }

    func setSeen(_ seen: Bool, for index: Int) {
        model.items[index].readed = seen
        model.items[index].new = false
        rssFeedProvider.saveState()
    }
}
