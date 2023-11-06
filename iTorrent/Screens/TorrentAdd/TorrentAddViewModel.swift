//
//  TorrentAddViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 06/11/2023.
//

import LibTorrent
import MvvmFoundation

extension TorrentAddViewModel {
    struct Config {
        var torrentFile: TorrentFile
        var rootDirectory: PathNode?
    }
}

class TorrentAddViewModel: BaseViewModelWith<TorrentAddViewModel.Config> {
    private var torrentFile: TorrentFile!
    private var rootDirectory: PathNode!
    private var keys: [String]!
    private(set) var isRoot: Bool = false

    override func prepare(with model: Config) {
        torrentFile = model.torrentFile
        isRoot = model.rootDirectory == nil
        rootDirectory = model.rootDirectory ?? generateRoot()
        keys = rootDirectory.storage
            .sorted(by: { first, second in
                let f = first.value.name
                let s = second.value.name
                return f.localizedCaseInsensitiveCompare(s) == .orderedAscending
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

extension TorrentAddViewModel {
    var title: String {
        rootDirectory.name
    }

    var filesCount: Int {
        keys.count
    }

    func node(at index: Int) -> Node {
        rootDirectory.storage[keys[index]]!
    }

    func fileModel(for index: Int) -> TorrentAddFileItemViewModel {
        .init(with: (torrentFile, index))
    }

    func pathModel(for path: PathNode) -> TorrentAddDirectoryItemViewModel {
        .init(with: (torrentFile, path, path.name))
    }

    func select(at index: Int) -> Bool {
        switch rootDirectory.storage[keys[index]] {
        case let path as PathNode:
            navigate(to: TorrentAddViewModel.self, with: .init(torrentFile: torrentFile, rootDirectory: path), by: .show)
            return false
        default:
            return true
        }
    }

    func cancel() {
        dismiss()
    }

    func download() {
        TorrentService.shared.addTorrent(by: torrentFile)
        dismiss()
    }
}

private extension TorrentAddViewModel {
    func generateRoot() -> PathNode {
        var root: PathNode = .init(name: torrentFile.name)

        torrentFile.files.forEach { file in
            let pathComponents = file.path.components(separatedBy: "/")
            root.append(path: pathComponents, index: Int(file.index))
        }

        if let newRoot = root.storage.first?.value as? PathNode {
            root = newRoot
        }

//        root.name = "Files"
        return root
    }
}
