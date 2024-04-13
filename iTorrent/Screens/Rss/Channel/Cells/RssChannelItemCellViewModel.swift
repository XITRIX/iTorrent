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
    @Published var subtitle: String?
    @Published var date: String?
    @Published var isNew: Bool = true
    @Published var isReaded: Bool = false
    var model: RssItemModel!

    override func prepare(with model: Config) {
//        link = model.rssModel.link
        update(with: model.rssModel)
        selectAction = model.selectAction
    }

    func update(with rssModel: RssItemModel) {
        model = rssModel
        title = rssModel.title ?? ""
        isNew = rssModel.new
        isReaded = rssModel.readed
        if let modelDate = rssModel.date {
            date = Date().offset(from: modelDate)
        }
    }

    override func hash(into hasher: inout Hasher) {
        hasher.combine(model)
    }

    override func isEqual(to other: MvvmViewModel) -> Bool {
        guard let other = other as? Self else { return false }
        return model == other.model
    }
}
