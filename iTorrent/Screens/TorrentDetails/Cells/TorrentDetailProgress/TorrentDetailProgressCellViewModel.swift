//
//  TorrentDetailProgressCellViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 31/10/2023.
//

import Foundation

class TorrentDetailProgressCellViewModel: BaseViewModel, ObservableObject {
    @Published var title: String = ""
    @Published var progress: Double = 0

    init(title: String = "", progress: Double = 0) {
        self.title = title
        self.progress = progress
    }

    required init() {
        fatalError("init() has not been implemented")
    }

    override func hash(into hasher: inout Hasher) {
        hasher.combine(title)
    }
}
