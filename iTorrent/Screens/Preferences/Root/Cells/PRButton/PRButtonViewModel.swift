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
        var removeAction: (() -> Void)? = nil
        var title: String
        var tintedTitle: Bool = false
        var isBold: Bool = false
        var value: AnyPublisher<String, Never>?
        var canReorder: Bool = false
        var tinted: Bool = true
        var singleLine: Bool = false
        var accessories: [UICellAccessory] = []
        var selectAction: (() -> Void)? = {}
    }
}

class PRButtonViewModel: BaseViewModelWith<PRButtonViewModel.Config>, ObservableObject, MvvmSelectableProtocol, MvvmReorderableProtocol {
    var selectAction: (() -> Void)?

    var id: String?
    @Published var title = ""
    @Published var tintedTitle: Bool = false
    @Published var isBold: Bool = false
    @Published var value: String = ""
    @Published var tinted: Bool = true
    @Published var singleLine: Bool = false
    @Published var canReorder: Bool = false
    @Published var accessories: [UICellAccessory] = []
    @Published var removeAction: (() -> Void)?

    var metadata: Any?

    override func prepare(with model: Config) {
        id = model.id
        title = model.title
        tintedTitle = model.tintedTitle
        isBold = model.isBold
        if let value = model.value {
            value.assign(to: &self.$value)
        }
        accessories = model.accessories
        selectAction = model.selectAction
        canReorder = model.canReorder
        tinted = model.tinted
        singleLine = model.singleLine
        removeAction = model.removeAction
    }

    override func isEqual(to other: MvvmViewModel) -> Bool {
        guard let other = other as? Self else { return false }
        return id == other.id && 
            title == other.title &&
            isBold == other.isBold &&
            accessories.count == other.accessories.count
    }

    override func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(isBold)
        hasher.combine(accessories.count)
    }
}
