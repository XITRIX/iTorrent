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
    }
}

class PRSwitchViewModel: BaseViewModelWith<PRSwitchViewModel.Config>, ObservableObject {
    var id: String?
    @Published var title = ""
    var value: Binding<Bool> = .constant(false)


    override func prepare(with model: Config) {
        id = model.id
        title = model.title
        value = model.value
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
