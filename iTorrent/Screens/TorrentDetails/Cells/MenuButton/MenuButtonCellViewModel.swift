//
//  MenuButtonCellViewModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 03.04.2026.
//

import Combine
import UIKit
import MvvmFoundation

extension MenuButtonCellViewModel {
    struct Config {
        var title: String
        var isBold: Bool = false
        var dismissSelection: () -> Void
    }
}

class MenuButtonCellViewModel: BaseViewModelWith<MenuButtonCellViewModel.Config>, ObservableObject, MvvmSelectableProtocol, MvvmReorderableProtocol {
    var selectAction: (() -> Void)?
    var dismissSelection: (() -> Void)?

    @Published var title: String = ""
    @Published var isBold: Bool = false
    @Published var value: NSAttributedString?
    @Published var tinted: Bool = true
    @Published var canReorder: Bool = false
    @Published var menu: UIMenu = .init()


    override func prepare(with model: Config) {
        title = model.title
        isBold = model.isBold
        dismissSelection = model.dismissSelection
    }
}
