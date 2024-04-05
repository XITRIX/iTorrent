//
//  TorrentAddViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 06/11/2023.
//

import LibTorrent
import MvvmFoundation
import Combine

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

    let updatePublisher = CurrentValueRelay<Void>(())

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

    override func willAppear() {
        updatePublisher.send(())
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
        .init(with: (torrentFile, index, { [unowned self] in
            updatePublisher.send(())
        }))
    }

    func pathModel(for path: PathNode) -> TorrentAddDirectoryItemViewModel {
        .init(with: (torrentFile, path, path.name, { [unowned self] in
            updatePublisher.send(())
        }))
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

    func setAllFilesPriority(_ priority: FileEntry.Priority) {
        torrentFile.setAllFilesPriority(priority)
        updatePublisher.send(())
    }

    var diskTextPublisher: AnyPublisher<String, Never> {
        updatePublisher.map { [unowned self] _ in
            var selected: UInt64 = 0
            var total: UInt64 = 0
            torrentFile.files.forEach({ file in
                total += file.size
                if file.priority != .dontDownload {
                    selected += file.size
                }
            })
            return "\(selected.bitrateToHumanReadable) / \(total.bitrateToHumanReadable)"
        }.eraseToAnyPublisher()
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
