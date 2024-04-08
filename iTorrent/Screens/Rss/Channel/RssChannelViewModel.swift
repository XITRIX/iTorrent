//
//  RssChannelViewModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 08.04.2024.
//

import Combine
import MvvmFoundation

class RssChannelViewModel: BaseCollectionViewModelWith<RssModel> {
    @Published var title: String = ""
    var model: RssModel!

    override func prepare(with model: RssModel) {
        self.model = model
        title = model.title
        disposeBag.bind {
            model.$items.sink { [unowned self] models in
                reload(with: models)
            }
        }
    }
}

private extension RssChannelViewModel {
    func reload(with models: [RssItemModel]) {
        var sections: [MvvmCollectionSectionModel] = []
        defer { self.sections = sections }

        sections.append(.init(id: "rss", style: .plain, items: models.map { model in
            RssChannelItemCellViewModel(with: .init(rssModel: model, selectAction: { [unowned self] in
                navigate(to: RssDetailsViewModel.self, with: model, by: .detail(asRoot: true))
            }))
        }))
    }
}
