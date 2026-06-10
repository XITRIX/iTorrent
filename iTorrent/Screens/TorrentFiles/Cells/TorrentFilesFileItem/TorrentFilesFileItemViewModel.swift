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
    var file: TorrentSession.Handle.Snapshot.FileEntrySnapshot { get }
    var updatePublisher: AnyPublisher<Void, Never> { get }
    var selected: PassthroughSubject<Void, Never> { get }
    var path: URL { get }
    var showProgress: Bool { get }

    func setPriority(_ priority: FileEntry.Priority)
}

class TorrentFilesFileItemViewModel: BaseViewModelWith<(TorrentSession.Handle, Int)>, MvvmSelectableProtocol, FileItemViewModelProtocol {
    var selectAction: (() -> Void)?
    var previewAction: (() -> Void)?

    var torrentHandle: TorrentSession.Handle!
    var index: Int = 0

    let selected = PassthroughSubject<Void, Never>()
    var showProgress: Bool { true }

    override func prepare(with model: (TorrentSession.Handle, Int)) {
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

    var updatePublisher: AnyPublisher<Void, Never> {
        torrentHandle.updatePublisher
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    var file: TorrentSession.Handle.Snapshot.FileEntrySnapshot {
        currentSnapshot.files[index]
    }

    var path: URL {
        guard let downloadPath = currentSnapshot.downloadPath
        else {
            assertionFailure("downloadPath cannot be nil for this object")
            return URL(string: "/")!
        }
        return downloadPath.appending(path: file.path)
    }

    func setPriority(_ priority: FileEntry.Priority) {
        Task {
            await torrentHandle.setFilePriority(priority, at: index)
        }
    }

    private var currentSnapshot: TorrentSession.Handle.Snapshot {
        guard let snapshot = torrentHandle.currentSnapshot else {
            fatalError("Snapshot should exist for active torrent handle")
        }
        return snapshot
    }
}

extension TorrentSession.Handle.Snapshot.FileEntrySnapshot {
    var progress: Double {
        guard size != 0 else { return 0 }
        return Double(downloaded) / Double(size)
    }
}
