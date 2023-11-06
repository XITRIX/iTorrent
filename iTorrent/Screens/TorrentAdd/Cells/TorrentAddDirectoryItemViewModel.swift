//
//  TorrentAddDirectoryItemViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 06/11/2023.
//

import Combine
import LibTorrent
import MvvmFoundation

class TorrentAddDirectoryItemViewModel: BaseViewModelWith<(TorrentFile, PathNode, String)>, DictionaryItemViewModelProtocol {
    var torrentFile: TorrentFile!
    var name: String = ""
    var node: PathNode!

    override func prepare(with model: (TorrentFile, PathNode, String)) {
        torrentFile = model.0
        node = model.1
        name = model.2
    }

    var updatePublisher: AnyPublisher<TorrentHandle, Never> {
        Just(.init()).eraseToAnyPublisher()
    }
}
