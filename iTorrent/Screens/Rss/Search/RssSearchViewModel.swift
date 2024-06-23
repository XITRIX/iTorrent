//
//  RssSearchViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 22/04/2024.
//

import Combine
import MvvmFoundation
import Foundation

class RssSearchViewModel: BaseCollectionViewModel {
    @Published var searchQuery: String = ""

    required init() {
        super.init()
        binding()
    }

    private var items: [RssChannelItemCellViewModel] = []
    @Injected private var rssProvider: RssFeedProvider
}

extension RssSearchViewModel {
    var emptyContentType: AnyPublisher<EmptyType?, Never> {
        Publishers.combineLatest($sections, $searchQuery) { sections, searchQuery in
            if sections.isEmpty || sections.allSatisfy({ $0.items.isEmpty }) {
                if !searchQuery.isEmpty { return EmptyType.badSearch }
                return EmptyType.noData
            }
            return nil
        }.eraseToAnyPublisher()
    }
}

private extension RssSearchViewModel {
    func binding() {
        disposeBag.bind {
            let rssItems = rssProvider.updatePublisher.map { [rssProvider] _ in
                rssProvider.rssModels.flatMap { $0.items }
            }

            Publishers.combineLatest(rssItems, $searchQuery) { models, searchQuery in
                Self.filter(models: models, by: searchQuery)
            }
            .sink { [unowned self] values in
                reload(values)
            }
        }
    }

    func reload(_ rssItems: [RssItemModel]) {
        // TODO: Need to rewrite this DispatchQueue mess
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            items = rssItems
                .sorted(by: { $0.date ?? .distantPast > $1.date ?? .distantPast })
                .map { model in
                    let vm: RssChannelItemCellViewModel
                    if let existing = items.first(where: { $0.model == model }) {
                        vm = existing
                    } else {
                        vm = RssChannelItemCellViewModel()
                    }

                    vm.prepare(with: .init(rssModel: model, selectAction: { [unowned self, weak vm] in
                        setSeen(true, for: model)
                        vm?.isNew = false
                        vm?.isReaded = true
                        navigate(to: RssDetailsViewModel.self, with: model, by: .detail(asRoot: true))
                        dismissSelection.send()
                    }))

                    return vm
                }.removingDuplicates()

            DispatchQueue.main.async { [self] in
                sections = [.init(id: "rss", style: .plain, items: items)]
            }
        }
    }

    func setSeen(_ seen: Bool, for itemModel: RssItemModel) {
        Task.detached(priority: .userInitiated) { [rssProvider] in
            outerLoop: for channel in rssProvider.rssModels {
                for itemIndex in 0 ..< channel.items.count {
                    guard channel.items[itemIndex] == itemModel else { continue }
                    await MainActor.run {
                        channel.items[itemIndex].readed = seen
                        channel.items[itemIndex].new = false
                        rssProvider.saveState()
                    }
                    break outerLoop
                }
            }
        }
    }

    static func filter(models: [RssItemModel], by searchQuery: String) -> [RssItemModel] {
        models.filter { model in
            searchQuery.split(separator: " ").allSatisfy { (model.title ?? "").localizedCaseInsensitiveContains($0) } ||
                searchQuery.split(separator: " ").allSatisfy { (model.description ?? "").localizedCaseInsensitiveContains($0) }
        }
    }
}
