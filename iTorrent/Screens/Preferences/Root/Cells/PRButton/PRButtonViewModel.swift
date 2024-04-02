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
        var accessories: [UICellAccessory] = []
        var selectAction: () -> Void = {}
    }
}

class PRButtonViewModel: BaseViewModelWith<PRButtonViewModel.Config>, ObservableObject, MvvmSelectableProtocol {
    var selectAction: (() -> Void)?

    @Published var title = ""
    @Published var value: String = ""
    @Published var accessories: [UICellAccessory] = []

    override func prepare(with model: Config) {
        title = model.title
        model.value.assign(to: &$value)
        accessories = model.accessories
        selectAction = model.selectAction
    }
}
