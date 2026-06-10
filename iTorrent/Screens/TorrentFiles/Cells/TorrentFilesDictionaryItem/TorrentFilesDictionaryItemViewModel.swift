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
    var updatePublisher: AnyPublisher<Void, Never> { get }
    var name: String { get }
    var node: PathNode! { get }
    var progress: Double? { get }
    var segmentedProgress: [Double]? { get }
    func setPriority(_ priority: FileEntry.Priority)
    func getPriority(for index: Int) -> FileEntry.Priority
}

class TorrentFilesDictionaryItemViewModel: BaseViewModelWith<(TorrentSession.Handle, PathNode, String)>, DictionaryItemViewModelProtocol {
    var torrentHandle: TorrentSession.Handle!
    var name: String = ""
    var node: PathNode!

    override func prepare(with model: (TorrentSession.Handle, PathNode, String)) {
        torrentHandle = model.0
        node = model.1
        name = model.2
    }

    var updatePublisher: AnyPublisher<Void, Never> {
        torrentHandle.updatePublisher
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    func setPriority(_ priority: FileEntry.Priority) {
        let files = node.files.filter {
            let file = snapshotFile(at: $0)
            return file.downloaded < file.size || priority != .dontDownload
        }

        Task {
            await torrentHandle.setFilesPriority(priority, at: files)
        }
    }

    func getPriority(for index: Int) -> FileEntry.Priority {
        snapshotFile(at: index).priority
    }

    var progress: Double? {
        let files = node.files.map(snapshotFile(at:)).filter { $0.priority != .dontDownload }
        let toDownload = files.reduce(0, { $0 + $1.size })
        let downloaded = files.reduce(0, { $0 + $1.downloaded })

        guard toDownload != 0 else { return 1 }
        return Double(downloaded) / Double(toDownload)
    }

    var segmentedProgress: [Double]? {
        let files = node.files.map(snapshotFile(at:)).filter { $0.priority != .dontDownload }
        return files.flatMap(\.segmentedProgress)
    }

    private func snapshotFile(at index: Int) -> TorrentSession.Handle.Snapshot.FileEntrySnapshot {
        guard let snapshot = torrentHandle.currentSnapshot else {
            fatalError("Snapshot should exist for active torrent handle")
        }
        return snapshot.files[index]
    }
}
