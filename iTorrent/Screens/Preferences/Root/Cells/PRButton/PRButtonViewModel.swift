//
//  PRButtonViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 08/11/2023.
//

import MvvmFoundation
import Combine
import SwiftUI

extension PRButtonViewModel {
    struct Config {
        var title: String
        var value: AnyPublisher<String, Never> = Just("").eraseToAnyPublisher()
        var canReorder: Bool = false
        var tinted: Bool = true
        var singleLine: Bool = false
        var accessories: [UICellAccessory] = []
        var selectAction: () -> Void = {}
    }
}

class PRButtonViewModel: BaseViewModelWith<PRButtonViewModel.Config>, ObservableObject, MvvmSelectableProtocol, MvvmReorderableProtocol {
    var selectAction: (() -> Void)?

    @Published var title = ""
    @Published var value: String = ""
    @Published var tinted: Bool = true
    @Published var singleLine: Bool = false
    @Published var canReorder: Bool = false
    @Published var accessories: [UICellAccessory] = []

    var metadata: Any?

    override func prepare(with model: Config) {
        title = model.title
        model.value.assign(to: &$value)
        accessories = model.accessories
        selectAction = model.selectAction
        canReorder = model.canReorder
        tinted = model.tinted
        singleLine = model.singleLine
    }

    override func isEqual(to other: MvvmViewModel) -> Bool {
        guard let other = other as? Self else { return false }
        return title == other.title
    }

    override func hash(into hasher: inout Hasher) {
        hasher.combine(title)
    }
}
