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
        var rssModel: RssItemSnapshot
        var selectAction: (() -> Void)?
    }
}

class RssChannelItemCellViewModel: BaseViewModelWith<RssChannelItemCellViewModel.Config>, MvvmSelectableProtocol {
    var selectAction: (() -> Void)?

    @Published var title: String = ""
    @Published var subtitle: String?
    @Published var date: String?
    @Published var isNew: Bool = true
    @Published var isReaded: Bool = false
    var model: RssItemSnapshot!

    override func prepare(with model: Config) {
        update(with: model.rssModel)
        selectAction = model.selectAction
    }

    func update(with rssModel: RssItemSnapshot) {
        model = rssModel
        title = rssModel.title ?? ""
        subtitle = rssModel.description
        isNew = rssModel.new
        isReaded = rssModel.readed
        if let modelDate = rssModel.date {
            date = Date().offset(from: modelDate)
        } else {
            date = nil
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
