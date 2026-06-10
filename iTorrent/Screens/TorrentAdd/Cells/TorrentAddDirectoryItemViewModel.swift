//
//  TorrentAddDirectoryItemViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 06/11/2023.
//

import Combine
import LibTorrent
import MvvmFoundation

class TorrentAddDirectoryItemViewModel: BaseViewModelWith<(TorrentSession.AddPreview, PathNode, String, ()->Void)>, DictionaryItemViewModelProtocol {
    let progress: Double? = nil
    let segmentedProgress: [Double]? = nil

    var localUpdatePublisher = PassthroughRelay<Void>()
    var preview: TorrentSession.AddPreview!
    var name: String = ""
    var node: PathNode!
    var onPriorityUpdated: (() -> Void)?

    override func prepare(with model: (TorrentSession.AddPreview, PathNode, String, ()->Void)) {
        preview = model.0
        node = model.1
        name = model.2
        onPriorityUpdated = model.3
    }

    var updatePublisher: AnyPublisher<Void, Never> {
        localUpdatePublisher.eraseToAnyPublisher()
    }

    func setPriority(_ priority: FileEntry.Priority) {
        preview.setFilesPriority(priority, at: node.files)
        onPriorityUpdated?()
        localUpdatePublisher.send()
    }

    func getPriority(for index: Int) -> FileEntry.Priority {
        preview.file(at: index).priority
    }
}
