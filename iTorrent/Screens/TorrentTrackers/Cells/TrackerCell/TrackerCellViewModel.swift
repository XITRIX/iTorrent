//
//  TrackerCellViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 10/11/2023.
//

import Foundation
import MvvmFoundation
import LibTorrent

class TrackerCellViewModel: BaseViewModelWith<TorrentTracker>, ObservableObject {
    @Published var title: String = ""

    override func prepare(with model: TorrentTracker) {
        title = model.trackerUrl
    }
}
