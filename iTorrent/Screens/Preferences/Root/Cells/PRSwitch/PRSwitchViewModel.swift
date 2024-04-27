//
//  PRSwitchViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 08/11/2023.
//

import MvvmFoundation
import Combine
import SwiftUI

extension PRSwitchViewModel {
    struct Config {
        var id: String?
        var title: String
        var value: Binding<Bool>
        var isDangerous: Bool = false
    }
}

class PRSwitchViewModel: BaseViewModelWith<PRSwitchViewModel.Config>, ObservableObject {
    var id: String?
    @Published var title = ""
    var value: Binding<Bool> = .constant(false)
    @Published var isDangerous: Bool = false

    override func prepare(with model: Config) {
        id = model.id
        title = model.title
        value = model.value
        isDangerous = model.isDangerous
    }


    override func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(isDangerous)
    }
}
