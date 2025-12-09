//
//  TorrentFilesModels.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 12.12.2025.
//

import LibTorrent

class Node: Hashable {
    var name: String = ""
    var files: [Int] { [] }

    init() {}

    static func == (lhs: Node, rhs: Node) -> Bool {
        lhs.name == rhs.name && lhs.files == rhs.files
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(files)
    }
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

extension PathNode {
    static func generateRoot(rootName: String, files: [FileEntry]) -> PathNode {
        var root: PathNode = .init(name: rootName)

        files.forEach { file in
            let pathComponents = file.path.components(separatedBy: "/")
            root.append(path: pathComponents, index: Int(file.index))
        }

        if let newRoot = root.storage.first?.value as? PathNode {
            root = newRoot
        }

        root.name = %"details.actions.files"
        return root
    }

    func makeKeys() -> [String] {
        storage
            .sorted(by: { first, second in
                let f = first.value.name
                let s = second.value.name
                return f.localizedStandardCompare(s) == .orderedAscending
            })
            .sorted(by: { first, second in
                if !first.key.starts(with: "./"), !second.key.starts(with: "./") {
                    let f = first.value.name
                    let s = second.value.name
                    return f.localizedStandardCompare(s) == .orderedAscending
                }
                return !first.key.starts(with: "./")
            })
            .map { $0.key }
    }
}
