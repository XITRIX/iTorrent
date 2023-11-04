//
//  TorrentFilesFileItemViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 03/11/2023.
//

import MvvmFoundation
import LibTorrent
import Combine
import UIKit

class TorrentFilesFileItemViewModel: BaseViewModelWith<(TorrentHandle, Int)>, ObservableObject {
    var torrentHandle: TorrentHandle!
    var index: Int = 0

    @Published var reload: Bool = false

    override func prepare(with model: (TorrentHandle, Int)) {
        torrentHandle = model.0
        index = model.1
    }

    override func hash(into hasher: inout Hasher) {
        hasher.combine(file.name)
        hasher.combine(file.path)
    }

    var updatePublisher: AnyPublisher<TorrentHandle, Never> {
        torrentHandle.updatePublisher.eraseToAnyPublisher()
    }

    var file: FileEntry {
        torrentHandle.getFileAt(Int32(index))
    }

    var path: URL {
        TorrentService.downloadPath.appending(path: file.path)
    }
}
