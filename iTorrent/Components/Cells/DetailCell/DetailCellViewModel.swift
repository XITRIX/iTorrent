//
//  DetailCellViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 30/10/2023.
//

import MvvmFoundation

// extension DetailCellViewModel {
//    struct Config {
//        var title: String = ""
//        var detail: String = ""
//    }
// }

class DetailCellViewModel: BaseViewModel, ObservableObject {
    @Published var title: String = ""
    @Published var detail: String = ""
    @Published var spacer: Double = 0

    init(title: String = "", detail: String = "", spacer: Double = 24) {
        self.title = title
        self.detail = detail
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
