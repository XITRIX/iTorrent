//
//  RssChannelViewModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 08.04.2024.
//

import Combine
import MvvmFoundation
import UIKit

class RssChannelViewModel: BaseCollectionViewModelWith<RssFeedSnapshot>, @unchecked Sendable {
    @Published var title: String = ""
    @Published var searchQuery: String = ""

    var model: RssFeedSnapshot!
    var items: [RssChannelItemCellViewModel] = []

    override func prepare(with model: RssFeedSnapshot) {
        self.model = model
        title = model.displayTitle
        reloadFilteredItems()
        bindUpdates()

        trailingSwipeActionsConfigurationProvider = { [unowned self] indexPath in
            let itemModel = items[indexPath.item].model!
            let readed = itemModel.readed
            let action = UIContextualAction(style: .normal, title: readed ? %"rsschannel.unseen" : %"rsschannel.seen", handler: { [unowned self] _, _, completion in
                setSeen(!readed, for: itemModel)
                completion(true)
            })
            action.backgroundColor = PreferencesStorage.shared.tintColor
            return .init(actions: [action])
        }

        refreshTask = { [weak self] in
            guard let self else { return }
            do { _ = try await rssFeedProvider.refreshFeed(id: model.id) }
            catch {}
        }
    }

    func readAll() {
        Task { [model, rssFeedProvider] in
            await rssFeedProvider.markFeedRead(id: model.id)
        }
    }

    func setSeen(_ seen: Bool, for itemModel: RssItemSnapshot) {
        Task { [model, rssFeedProvider] in
            await rssFeedProvider.markItemRead(feedID: model.id, itemID: itemModel.id, read: seen)
        }
    }

    private var updatesTask: Task<Void, Never>?
    @Injected private var rssFeedProvider: RssFeedProvider
}

private extension RssChannelViewModel {
    func bindUpdates() {
        disposeBag.bind {
            $searchQuery.sink { [unowned self] _ in
                reloadFilteredItems()
            }
        }

        updatesTask = Task { [weak self, rssFeedProvider] in
            for await feeds in await rssFeedProvider.updates() {
                guard let self else { return }
                guard let feed = feeds.first(where: { $0.id == self.model.id }) else { continue }
                await self.apply(feed)
            }
        }
    }

    @MainActor
    func apply(_ feed: RssFeedSnapshot) {
        model = feed
        title = feed.displayTitle
        reloadFilteredItems()
    }

    func reloadFilteredItems() {
        reload(with: Self.filter(models: model.items, by: searchQuery))
    }

    func reload(with models: [RssItemSnapshot]) {
        items = models.map { model in
            let vm: RssChannelItemCellViewModel
            if let existing = items.first(where: { $0.model.id == model.id }) {
                vm = existing
            } else {
                vm = RssChannelItemCellViewModel()
            }

            vm.prepare(with: .init(rssModel: model, selectAction: { [unowned self] in
                setSeen(true, for: model)
                navigate(to: RssDetailsViewModel.self, with: model, by: .detail(asRoot: true))
            }))

            return vm
        }.removingDuplicates()

        sections = [.init(id: "rss", style: .plain, items: items)]
    }

    static func filter(models: [RssItemSnapshot], by searchQuery: String) -> [RssItemSnapshot] {
        let query = RssSearchQuery(searchQuery)
        return models.filter { $0.matches(query) }
    }
}
