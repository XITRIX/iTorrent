//
//  TorrentFilesViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 03/11/2023.
//

import LibTorrent
import MvvmFoundation


extension TorrentFilesViewModel {
    struct Config {
        var torrentHandle: TorrentSession.Handle
        var rootDirectory: PathNode?
    }
}

class TorrentFilesViewModel: BaseViewModelWith<TorrentFilesViewModel.Config> {
    private(set) var torrentHandle: TorrentSession.Handle!
    private var rootDirectory: PathNode!
    private var keys: [String] = []

    override func prepare(with model: Config) {
        torrentHandle = model.torrentHandle
        rootDirectory = model.rootDirectory ?? generateRoot()
        keys = rootDirectory.makeKeys()
    }
}

extension TorrentFilesViewModel {
    var title: String {
        rootDirectory.name
    }

    var filesCount: Int {
        keys.count
    }

    var downloadPath: URL {
        guard let downloadPath = snapshot.downloadPath
        else {
            assertionFailure("downloadPath cannot be nil for this object")
            return URL(string: "/")!
        }

        return downloadPath
    }

    var filesForPreview: [TorrentSession.Handle.Snapshot.FileEntrySnapshot] {
        filesForPreviewUnfiltered
        .filter {
            $0.downloaded >= $0.size
        }
    }

    var filesForPreviewUnfiltered: [TorrentSession.Handle.Snapshot.FileEntrySnapshot] {
        keys.flatMap {
            switch rootDirectory.storage[$0] {
            case let path as PathNode:
                return path.files
            case let file as FileNode:
                return [file.index]
            default:
                return []
            }
        }
        .map(snapshotFile(at:))
    }

    func canShareSelected(_ indexPaths: [IndexPath]) -> Bool {
        indexPaths.flatMap { indexPath in
            switch rootDirectory.storage[keys[indexPath.item]] {
            case let path as PathNode:
                return path.files
            case let file as FileNode:
                return [file.index]
            default:
                return []
            }
        }.contains {
            let file = snapshotFile(at: $0)
            return file.downloaded >= file.size
        }
    }

    func canChangePriorityForSelected(_ indexPaths: [IndexPath]) -> Bool {
        indexPaths.flatMap { indexPath in
            switch rootDirectory.storage[keys[indexPath.item]] {
            case let path as PathNode:
                return path.files
            case let file as FileNode:
                return [file.index]
            default:
                return []
            }
        }.contains {
            let file = snapshotFile(at: $0)
            return file.downloaded < file.size
        }
    }

    func shareSelected(_ indexPaths: [IndexPath]) {
        alertWithTimer(message: "This feature is not implemented yet")
    }

    func node(at index: Int) -> Node {
        rootDirectory.storage[keys[index]]!
    }

    func fileModel(for index: Int) -> TorrentFilesFileItemViewModel {
        .init(with: (torrentHandle, index))
    }

    func pathModel(for path: PathNode) -> TorrentFilesDictionaryItemViewModel {
        .init(with: (torrentHandle, path, path.name))
    }

    func select(at index: Int) -> Bool {
        switch rootDirectory.storage[keys[index]] {
        case let path as PathNode:
            navigate(to: TorrentFilesViewModel.self, with: .init(torrentHandle: torrentHandle, rootDirectory: path), by: .show)
            return false
        default:
            return true
        }
    }

    func setPriority(_ priority: FileEntry.Priority, at indexPaths: [IndexPath]) {
        let files = indexPaths.flatMap { indexPath in
            switch rootDirectory.storage[keys[indexPath.item]] {
            case let path as PathNode:
                return path.files
            case let file as FileNode:
                return [file.index]
            default:
                return []
            }
        }.filter {
            let file = snapshotFile(at: $0)
            return file.downloaded < file.size || priority != .dontDownload
        }

        Task {
            await torrentHandle.setFilesPriority(priority, at: files)
        }
    }
}

private extension TorrentFilesViewModel {
    var snapshot: TorrentSession.Handle.Snapshot {
        guard let snapshot = torrentHandle.currentSnapshot else {
            fatalError("Snapshot should exist for active torrent handle")
        }
        return snapshot
    }

    func generateRoot() -> PathNode {
        .generateRoot(rootName: "", files: snapshot.files)
    }

    func snapshotFile(at index: Int) -> TorrentSession.Handle.Snapshot.FileEntrySnapshot {
        snapshot.files[index]
    }
}
