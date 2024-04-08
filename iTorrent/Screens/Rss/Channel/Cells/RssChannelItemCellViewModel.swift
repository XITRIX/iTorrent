//
//  RssChannelItemCellViewModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 08.04.2024.
//

import MvvmFoundation
import Combine

extension RssChannelItemCellViewModel {
    struct Config {
        var rssModel: RssItemModel
        var selectAction: (() -> Void)?
    }
}

class RssChannelItemCellViewModel: BaseViewModelWith<RssChannelItemCellViewModel.Config>, MvvmSelectableProtocol {
    var selectAction: (() -> Void)?

    @Published var title: String = ""
    @Published var date: String = ""
    @Published var isNew: Bool = true

    override func prepare(with model: Config) {
        title = model.rssModel.title ?? ""
        isNew = model.rssModel.new
        selectAction = model.selectAction
    }
}
