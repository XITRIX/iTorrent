//
//  RssSearchViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 22/04/2024.
//

import Combine
import MvvmFoundation

class RssSearchViewModel: BaseCollectionViewModel {
    @Published var searchQuery: String = ""

    required init() {
        super.init()
        binding()
    }

    private var items: [RssChannelItemCellViewModel] = []
    @Injected private var rssProvider: RssFeedProvider
}

private extension RssSearchViewModel {
    func binding() {
        disposeBag.bind {
            let rssItems = rssProvider.$rssModels.map { model in
                Publishers.MergeMany(model.map { $0.$items })
                    .collect(model.count)
            }
            .switchToLatest()
            .map { $0.flatMap { $0 } }

            Publishers.combineLatest(rssItems, $searchQuery) { models, searchQuery in
                Self.filter(models: models, by: searchQuery)
            }.sink { [unowned self] values in
                reload(values)
            }
        }
    }

    func reload(_ rssItems: [RssItemModel]) {
        var sections: [MvvmCollectionSectionModel] = []
        defer { self.sections = sections }

        items = rssItems.map { model in
            let vm: RssChannelItemCellViewModel
            if let existing = items.first(where: { $0.model == model }) {
                vm = existing
            } else {
                vm = RssChannelItemCellViewModel()
            }

            vm.prepare(with: .init(rssModel: model, selectAction: { [unowned self] in
                setSeen(true, for: model)
                navigate(to: RssDetailsViewModel.self, with: model, by: .detail(asRoot: true))
                dismissSelection.send()
            }))

            return vm
        }.removingDuplicates()

        sections.append(.init(id: "rss", style: .plain, items: items))
    }

    func setSeen(_ seen: Bool, for itemModel: RssItemModel) {
//        guard let index = model.items.firstIndex(where: { $0 == itemModel })
//        else { return }
//
//        model.items[index].readed = seen
//        model.items[index].new = false
//        rssFeedProvider.saveState()
    }

    static func filter(models: [RssItemModel], by searchQuery: String) -> [RssItemModel] {
        models.filter { model in
            searchQuery.split(separator: " ").allSatisfy { (model.title ?? "").localizedCaseInsensitiveContains($0) } ||
                searchQuery.split(separator: " ").allSatisfy { (model.description ?? "").localizedCaseInsensitiveContains($0) }
        }
    }
}
