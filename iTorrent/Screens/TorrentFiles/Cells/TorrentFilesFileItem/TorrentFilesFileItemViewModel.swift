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

    func setPriority(_ priority: FileEntry.Priority)
}

class TorrentFilesFileItemViewModel: BaseViewModelWith<(TorrentHandle, Int)>, MvvmSelectableProtocol, FileItemViewModelProtocol {
    var selectAction: (() -> Void)?
    var torrentHandle: TorrentHandle!
    var index: Int = 0

    let selected = PassthroughSubject<Void, Never>()

    override func prepare(with model: (TorrentHandle, Int)) {
        torrentHandle = model.0
        index = model.1
        selectAction = { [unowned self] in
            selected.send(())
        }
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

    func setPriority(_ priority: FileEntry.Priority) {
        torrentHandle.setFilePriority(priority, at: index)
    }
}
