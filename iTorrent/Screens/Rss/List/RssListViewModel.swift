//
//  RssListViewModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 08.04.2024.
//

import Combine
import Foundation
import MvvmFoundation

class RssListViewModel: BaseCollectionViewModel, @unchecked Sendable {
    required init() {
        super.init()
        setup()
    }

    @Injected private var rssProvider: RssFeedProvider
}

extension RssListViewModel {
    var isEmpty: AnyPublisher<Bool, Never> {
        $sections.map { $0.isEmpty || $0.allSatisfy { $0.items.isEmpty } }
            .eraseToAnyPublisher()
    }

    var isRemoveAvailable: AnyPublisher<Bool, Never> {
        $selectedIndexPaths.map { !$0.isEmpty }
            .eraseToAnyPublisher()
    }

    func addFeed() {
        textInput(title: %"rsslist.add.title", placeholder: "https://", type: .URL, accept: %"common.add") { [unowned self] result in
            guard let result else { return }
            Task { try await rssProvider.addFeed(result) }
        }
    }

    func removeSelected() {
        let items = selectedIndexPaths.compactMap {
            (sections[$0.section].items[$0.item] as? RssFeedCellViewModel)?.model
        }

        alert(title: %"rsslist.remove.title", message: %"rsslist.remove.message", actions: [
            .init(title: %"common.cancel", style: .cancel),
            .init(title: %"common.delete", style: .destructive, action: { [rssProvider] in
                rssProvider.removeFeeds(items)
            })
        ])
    }

    func reorderItems(_ viewModels: [MvvmViewModel]) {
        let rssModels = viewModels.compactMap { $0 as? RssFeedCellViewModel }.compactMap { $0.model }
        DispatchQueue.main.async { [self] in
            rssProvider.rssModels = rssModels
        }
    }
}

private extension RssListViewModel {
    func setup() {
        Task { [rssProvider] in try await rssProvider.fetchUpdates() }
        disposeBag.bind {
            rssProvider.$rssModels.sink { [unowned self] models in
                var sections: [MvvmCollectionSectionModel] = []
                defer { self.sections = sections }

                sections.append(.init(id: "rss", items: models.map { model in
                    RssFeedCellViewModel(with: .init(rssModel: model, selectAction: { [unowned self] in
                        navigate(to: RssChannelViewModel.self, with: model, by: .show)
                    }))
                }))
            }
        }

        refreshTask = { [weak self] in
            do { try await self?.rssProvider.fetchUpdates() }
            catch {}
        }
    }
}
