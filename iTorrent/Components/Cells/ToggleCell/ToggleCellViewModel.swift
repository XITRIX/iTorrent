//
//  ToggleCellViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 02/11/2023.
//

import MvvmFoundation

// extension DetailCellViewModel {
//    struct Config {
//        var title: String = ""
//        var detail: String = ""
//    }
// }

class ToggleCellViewModel: BaseViewModel, ObservableObject {
    var selectAction: (() -> Void)?

    @Published var title: String = ""
    @Published var isOn: Bool = false
    @Published var spacer: Double = 0

    init(title: String = "", isOn: Bool = false, spacer: Double = 24) {
        self.title = title
        self.isOn = isOn
        self.spacer = spacer
    }

    required init() {
        fatalError("init() has not been implemented")
    }

    override func hash(into hasher: inout Hasher) {
        hasher.combine(title)
    }

//    override func isEqual(to other: MvvmViewModel) -> Bool {
//        guard let other = other as? Self else { return false }
//        return title == other.title
//    }
}
