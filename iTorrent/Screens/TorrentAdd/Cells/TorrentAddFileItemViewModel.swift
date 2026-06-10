//
//  TorrentAddFileItemViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 06/11/2023.
//

import Combine
import LibTorrent
import MvvmFoundation

class TorrentAddFileItemViewModel: BaseViewModelWith<(TorrentSession.AddPreview, Int, ()->Void)>, MvvmSelectableProtocol, FileItemViewModelProtocol {
    var localUpdatePublisher = PassthroughRelay<Void>()
    private var preview: TorrentSession.AddPreview!
    private var internalFile: TorrentSession.Handle.Snapshot.FileEntrySnapshot!
    private var index: Int = 0

    var selectAction: (() -> Void)?
    var showProgress: Bool { false }
    var onPriorityUpdated: (() -> Void)?

    var file: TorrentSession.Handle.Snapshot.FileEntrySnapshot {
        internalFile
    }

    var updatePublisher: AnyPublisher<Void, Never> {
        localUpdatePublisher.eraseToAnyPublisher()
    }

    let selected = PassthroughSubject<Void, Never>()

    var path: URL {
        TorrentService.downloadPath.appending(path: file.path)
    }

    func setPriority(_ priority: FileEntry.Priority) {
        preview.setFilePriority(priority, at: index)
        onPriorityUpdated?()
    }

    override func prepare(with model: (TorrentSession.AddPreview, Int, ()->Void)) {
        preview = model.0
        index = model.1
        onPriorityUpdated = model.2
        internalFile = preview.file(at: index)
        selectAction = { [unowned self] in
            selected.send()
        }
    }
}
