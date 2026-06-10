//
//  RssSearchViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 22/04/2024.
//

import Combine
import Foundation
import MvvmFoundation

class RssSearchViewModel: BaseCollectionViewModel, @unchecked Sendable {
    @Published var searchQuery: String = ""

    required init() {
        super.init()
        binding()
    }

    private var reloadTask: Task<Void, Never>?
    private var updatesTask: Task<Void, Never>?
    private var items: [RssChannelItemCellViewModel] = []
    @Injected private var rssProvider: RssFeedProvider
}

extension RssSearchViewModel {
    var emptyContentType: AnyPublisher<EmptyType?, Never> {
        Publishers.combineLatest($sections, $searchQuery) { sections, searchQuery in
            if sections.isEmpty || sections.allSatisfy({ $0.items.isEmpty }) {
                if !searchQuery.isEmpty { return EmptyType.badSearch(searchQuery) }
                return EmptyType.noData
            }
            return nil
        }.eraseToAnyPublisher()
    }
}

private extension RssSearchViewModel {
    func binding() {
        disposeBag.bind {
            $searchQuery
                .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: true)
                .sink { [unowned self] query in
                    search(query)
                }
        }

        updatesTask = Task { [weak self, rssProvider] in
            for await _ in await rssProvider.updates() {
                await self?.searchCurrentQuery()
            }
        }
    }

    @MainActor
    func searchCurrentQuery() {
        search(searchQuery)
    }

    func search(_ query: String) {
        reloadTask?.cancel()
        guard !RssSearchQuery(query).tokens.isEmpty else {
            Task { @MainActor in
                reload([])
            }
            return
        }

        reloadTask = Task { [weak self, rssProvider] in
            let result = await rssProvider.searchItems(query: query)
            guard !Task.isCancelled else { return }
            await self?.reload(result)
        }
    }

    @MainActor
    func reload(_ results: [RssSearchResultSnapshot]) {
        let existingItems = Dictionary(uniqueKeysWithValues: items.compactMap { item in
            item.model.map { ($0.id, item) }
        })

        items = results.map { result in
            let model = result.item
            let vm = existingItems[model.id] ?? RssChannelItemCellViewModel()

            vm.prepare(with: .init(rssModel: model, selectAction: { [unowned self, weak vm] in
                setSeen(true, for: result)
                vm?.isNew = false
                vm?.isReaded = true
                navigate(to: RssDetailsViewModel.self, with: model, by: .detail(asRoot: true))
                dismissSelection.send()
            }))

            return vm
        }.removingDuplicates()

        sections = [.init(id: "rss", style: .plain, items: items)]
    }

    func setSeen(_ seen: Bool, for result: RssSearchResultSnapshot) {
        Task { [rssProvider] in
            await rssProvider.markItemRead(feedID: result.feedID, itemID: result.item.id, read: seen)
        }
    }
}
