//
//  RssDetailsViewModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 08.04.2024.
//

import MvvmFoundation
import Combine

class RssDetailsViewModel: BaseViewModelWith<RssItemModel> {
    var rssModel: RssItemModel!
    @Published var title: String = ""

    override func prepare(with model: RssItemModel) {
        rssModel = model

        title = model.title ?? ""
    }
}
