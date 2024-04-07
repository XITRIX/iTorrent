//
//  TrackerCellViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 10/11/2023.
//

import Foundation
import MvvmFoundation
import LibTorrent

class TrackerCellViewModel: BaseViewModelWith<TorrentTracker>, MvvmLongPressProtocol, ObservableObject {
    var longPressAction: (() -> Void)?
    
    @Published var title: String = ""
    @Published var message: String?
    @Published var seeds: Int = 0
    @Published var peers: Int = 0
    @Published var leeches: Int = 0
    @Published var state: TorrentTracker.State = .updating
    @Published var url: String!

    override func prepare(with model: TorrentTracker) {
        url = model.trackerUrl
        update(with: model)
    }

    func update(with model: TorrentTracker) {
        title = model.trackerUrl
        message = model.message
        seeds = model.seeds
        peers = model.peers
        leeches = model.leeches
        state = model.state
    }

    override func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
}
