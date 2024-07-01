//
//  TorrentFilesViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 03/11/2023.
//

import LibTorrent
import MvvmFoundation

class Node {
    var name: String = ""
    var files: [Int] { [] }
}

class FileNode: Node {
    let index: Int
    init(index: Int, name: String) {
        self.index = index
        super.init()
        self.name = name
    }

    override var files: [Int] { return [index] }
}

class PathNode: Node {
    var storage: [String: Node] = [:]

    init(name: String) {
        super.init()
        self.name = name
    }

    func append(path: [String], index: Int) {
        guard path.count > 1
        else {
            return storage["./\(index)"] = FileNode(index: index, name: path[0])
        }

        var path = path
        let next = path.removeFirst()

        var nextPathNode: PathNode! = storage[next] as? PathNode
        if nextPathNode == nil {
            nextPathNode = PathNode(name: next)
            storage[next] = nextPathNode
        }

        nextPathNode.append(path: path, index: index)
    }

    override var files: [Int] {
        storage.values.map { $0.files }.reduce([], +)
    }
}

extension TorrentFilesViewModel {
    struct Config {
        var torrentHandle: TorrentHandle
        var rootDirectory: PathNode?
    }

    enum PathItem {
        case directory([String: Node])
        case file(Int)
    }
}

class TorrentFilesViewModel: BaseViewModelWith<TorrentFilesViewModel.Config> {
    private var torrentHandle: TorrentHandle!
    private var rootDirectory: PathNode!
    private var keys: [String]!

    override func prepare(with model: Config) {
        torrentHandle = model.torrentHandle
        rootDirectory = model.rootDirectory ?? generateRoot()
        keys = rootDirectory.storage
            .sorted(by: { first, second in
                let f = first.value.name
                let s = second.value.name
                return f.localizedStandardCompare(s) == .orderedAscending
            })
            .sorted(by: { first, second in
                if !first.key.starts(with: "./"), !second.key.starts(with: "./") {
                    let f = first.value.name
                    let s = second.value.name
                    return f.localizedCaseInsensitiveCompare(s) == .orderedAscending
                }
                return !first.key.starts(with: "./")
            })
            .map { $0.key }
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
        torrentHandle.snapshot.downloadPath
    }

    var filesForPreview: [FileEntry] {
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
        .map { torrentHandle.snapshot.files[$0] }
        .filter {
            $0.downloaded >= $0.size
        }
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
            let file = torrentHandle.snapshot.files[$0]
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
            let file = torrentHandle.snapshot.files[$0]
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
            let file = torrentHandle.snapshot.files[$0]
            return file.downloaded < file.size || priority != .dontDownload
        }

        torrentHandle.setFilesPriority(priority, at: files.map { NSNumber(integerLiteral: $0) })
    }
}

private extension TorrentFilesViewModel {
    func generateRoot() -> PathNode {
        var root: PathNode = .init(name: "")

        torrentHandle.snapshot.files.forEach { file in
            let pathComponents = file.path.components(separatedBy: "/")
            root.append(path: pathComponents, index: Int(file.index))
        }

        if let newRoot = root.storage.first?.value as? PathNode {
            root = newRoot
        }

        root.name = %"details.actions.files"
        return root
    }
}
