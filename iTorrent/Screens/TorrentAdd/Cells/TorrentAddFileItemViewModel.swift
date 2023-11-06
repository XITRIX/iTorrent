//
//  TorrentAddFileItemViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 06/11/2023.
//

import Combine
import LibTorrent
import MvvmFoundation

class TorrentAddFileItemViewModel: BaseViewModelWith<(TorrentFile, Int)>, MvvmSelectableProtocol, FileItemViewModelProtocol {
    private var torrentFile: TorrentFile!
    private var internalFile: FileEntry!
    private var index: Int = 0

    var selectAction: (() -> Void)?

    var file: FileEntry {
        internalFile
    }

    var updatePublisher: AnyPublisher<TorrentHandle, Never> {
        Just(.init()).eraseToAnyPublisher()
    }

    let selected = PassthroughSubject<Void, Never>()

    var path: URL {
        TorrentService.downloadPath.appending(path: file.path)
    }

    func setPriority(_ priority: FileEntry.Priority) {
        torrentFile.setFilePriority(priority, at: index)
    }

    override func prepare(with model: (TorrentFile, Int)) {
        torrentFile = model.0
        index = model.1
        internalFile = torrentFile.getAt(Int32(index))
        selectAction = { [unowned self] in
            selected.send(())
        }
    }
}
