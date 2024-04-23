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
        var id: String?
        var title: String
        var value: AnyPublisher<String, Never>?// = Just("").eraseToAnyPublisher()
        var canReorder: Bool = false
        var tinted: Bool = true
        var singleLine: Bool = false
        var accessories: [UICellAccessory] = []
        var selectAction: () -> Void = {}
    }
}

class PRButtonViewModel: BaseViewModelWith<PRButtonViewModel.Config>, ObservableObject, MvvmSelectableProtocol, MvvmReorderableProtocol {
    var selectAction: (() -> Void)?

    var id: String?
    @Published var title = ""
    @Published var value: String = ""
    @Published var tinted: Bool = true
    @Published var singleLine: Bool = false
    @Published var canReorder: Bool = false
    @Published var accessories: [UICellAccessory] = []

    var metadata: Any?

    override func prepare(with model: Config) {
        id = model.id
        title = model.title
        if let value = model.value {
            value.assign(to: &self.$value)
        }
        accessories = model.accessories
        selectAction = model.selectAction
        canReorder = model.canReorder
        tinted = model.tinted
        singleLine = model.singleLine
    }

    override func isEqual(to other: MvvmViewModel) -> Bool {
        guard let other = other as? Self else { return false }
        return id == other.id && title == other.title
    }

    override func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
    }
}
