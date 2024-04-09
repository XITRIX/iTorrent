//
//  RssChannelItemCellViewModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 08.04.2024.
//

import Combine
import Foundation
import MvvmFoundation

extension RssChannelItemCellViewModel {
    struct Config {
        var rssModel: RssItemModel
        var selectAction: (() -> Void)?
    }
}

class RssChannelItemCellViewModel: BaseViewModelWith<RssChannelItemCellViewModel.Config>, MvvmSelectableProtocol {
    var selectAction: (() -> Void)?

//    private var link: URL!
    @Published var title: String = ""
    @Published var date: String = ""
    @Published var isNew: Bool = true

    override func prepare(with model: Config) {
//        link = model.rssModel.link
        title = model.rssModel.title ?? ""
        isNew = model.rssModel.new
        selectAction = model.selectAction
    }

//    override func hash(into hasher: inout Hasher) {
//        hasher.combine(link)
//    }
}
