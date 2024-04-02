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
        var title: String
        var value: Binding<Bool>
    }
}

class PRSwitchViewModel: BaseViewModelWith<PRSwitchViewModel.Config>, ObservableObject {
    @Published var title = ""
    var value: Binding<Bool> = .constant(false)

    override func prepare(with model: Config) {
        title = model.title
        value = model.value
    }
}
