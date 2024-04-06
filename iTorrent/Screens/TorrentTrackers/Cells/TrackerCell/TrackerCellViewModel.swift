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
    @Published var message: String?
    @Published var seeds: Int = 0
    @Published var peers: Int = 0
    @Published var leechs: Int = 0

    override func prepare(with model: TorrentTracker) {
        title = model.trackerUrl
        message = model.messages
        seeds = model.seeders
        peers = model.peers
        leechs = model.leechs
    }
}
