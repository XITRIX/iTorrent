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

protocol FileItemViewModelProtocol: MvvmViewModel {
    var file: FileEntry { get }
    var updatePublisher: AnyPublisher<TorrentHandle, Never> { get }
    var selected: PassthroughSubject<Void, Never> { get }
    var path: URL { get }
    var showProgress: Bool { get }

    func setPriority(_ priority: FileEntry.Priority)
}

class TorrentFilesFileItemViewModel: BaseViewModelWith<(TorrentHandle, Int)>, MvvmSelectableProtocol, FileItemViewModelProtocol {
    var selectAction: (() -> Void)?
    var previewAction: (() -> Void)?
    
    var torrentHandle: TorrentHandle!
    var index: Int = 0

    let selected = PassthroughSubject<Void, Never>()
    var showProgress: Bool { true }

    override func prepare(with model: (TorrentHandle, Int)) {
        torrentHandle = model.0
        index = model.1
        selectAction = { [unowned self] in
            if file.progress >= 1 {
                previewAction?()
            } else {
                selected.send()
            }
        }
    }

    override func hash(into hasher: inout Hasher) {
        hasher.combine(file.name)
        hasher.combine(file.path)
    }

    var updatePublisher: AnyPublisher<TorrentHandle, Never> {
        torrentHandle.updatePublisher.map { $0.handle }.eraseToAnyPublisher()
    }

    var file: FileEntry {
        torrentHandle.snapshot.files[index]
    }

    var path: URL {
        torrentHandle.snapshot.downloadPath.appending(path: file.path)
    }

    func setPriority(_ priority: FileEntry.Priority) {
        torrentHandle.setFilePriority(priority, at: index)
    }
}

extension FileEntry {
    var progress: Double {
        Double(downloaded) / Double(size)
    }
}
