//
//  TorrentAddDirectoryItemViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 06/11/2023.
//

import Combine
import LibTorrent
import MvvmFoundation

class TorrentAddDirectoryItemViewModel: BaseViewModelWith<(TorrentFile, PathNode, String, ()->Void)>, DictionaryItemViewModelProtocol {
    var localUpdatePublisher = PassthroughRelay<TorrentHandle>()
    var torrentFile: TorrentFile!
    var name: String = ""
    var node: PathNode!
    var onPriorityUpdated: (() -> Void)?

    override func prepare(with model: (TorrentFile, PathNode, String, ()->Void)) {
        torrentFile = model.0
        node = model.1
        name = model.2
        onPriorityUpdated = model.3
    }

    var updatePublisher: AnyPublisher<TorrentHandle, Never> {
        localUpdatePublisher.eraseToAnyPublisher()
    }

    func setPriority(_ priority: FileEntry.Priority) {
        torrentFile.setFilesPriority(priority, at: node.files.map { .init(integerLiteral: $0) })
        onPriorityUpdated?()
        localUpdatePublisher.send(.init())
    }

    func getPriority(for index: Int) -> FileEntry.Priority {
        torrentFile.getAt(Int32(index)).priority
    }
}
