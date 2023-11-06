//
//  TorrentFilesDictionaryItemViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 04/11/2023.
//

import Combine
import Foundation
import LibTorrent
import MvvmFoundation

protocol DictionaryItemViewModelProtocol: MvvmViewModelProtocol {
    var updatePublisher: AnyPublisher<TorrentHandle, Never> { get }
    var name: String { get }
    var node: PathNode! { get }
}

class TorrentFilesDictionaryItemViewModel: BaseViewModelWith<(TorrentHandle, PathNode, String)>, DictionaryItemViewModelProtocol {
    var torrentHandle: TorrentHandle!
    var name: String = ""
    var node: PathNode!

    override func prepare(with model: (TorrentHandle, PathNode, String)) {
        torrentHandle = model.0
        node = model.1
        name = model.2
    }

    var updatePublisher: AnyPublisher<TorrentHandle, Never> {
        torrentHandle.updatePublisher.eraseToAnyPublisher()
    }
}
