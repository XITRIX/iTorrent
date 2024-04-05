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
    var progress: Double? { get }
    var segmentedProgress: [Double]? { get }
    func setPriority(_ priority: FileEntry.Priority)
    func getPriority(for index: Int) -> FileEntry.Priority
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
        torrentHandle.updatePublisher.map { $0.handle }.eraseToAnyPublisher()
    }

    func setPriority(_ priority: FileEntry.Priority) {
        let files = node.files.filter {
            let file = torrentHandle.snapshot.files[$0]
            return file.downloaded < file.size || priority != .dontDownload
        }

        torrentHandle.setFilesPriority(priority, at: files.map { NSNumber.init(integerLiteral: $0) })
    }

    func getPriority(for index: Int) -> FileEntry.Priority {
        torrentHandle.snapshot.files[index].priority
    }

    var progress: Double? {
        let files = node.files.map { torrentHandle.snapshot.files[$0] }.filter { $0.priority != .dontDownload }
        let toDownload = files.reduce(0, { $0 + $1.size })
        let downloaded = files.reduce(0, { $0 + $1.downloaded })

        guard toDownload != 0 else { return 1 }
        return Double(downloaded) / Double(toDownload)
    }

    var segmentedProgress: [Double]? {
        let files = node.files.map { torrentHandle.snapshot.files[$0] }.filter { $0.priority != .dontDownload }
        return files.flatMap { $0.pieces.map { $0.doubleValue } }
    }
}
