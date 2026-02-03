//
//  TorrentFilesView.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 12.12.2025.
//

import SwiftUI
import LibTorrent
import Combine

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

struct TorrentFilesView: View {
    @StateObject private var viewModel: ViewModel

    init(torrentHandle: TorrentHandle, rootDirectory: PathNode?) {
        _viewModel = StateObject.init(wrappedValue: .init(torrentHandle: torrentHandle, rootDirectory: rootDirectory))
    }

    var body: some View {
        List {
            ForEach(viewModel.nodes(), id: \.self) { node in
                switch node {
                case let node as FileNode:
                    TorrentFilesFileView(node: node, viewModel: viewModel)
                case let node as PathNode:
                    Button("Dict: \(node.name)") {}
                        .focusable()
                default:
                    Text("")
                }
            }
        }
        .listStyle(.plain)
    }
}

extension TorrentFilesView {
    class ViewModel: ObservableObject {
        init(torrentHandle: TorrentHandle, rootDirectory: PathNode?) {
            self.torrentHandle = torrentHandle
            self.rootDirectory = rootDirectory ?? .generateRoot(rootName: "", files: torrentHandle.snapshot.files)
            keys = self.rootDirectory.makeKeys()
        }

        var filesCount: Int {
            keys.count
        }

        func node(at index: Int) -> Node {
            rootDirectory.storage[keys[index]]!
        }

        func nodes() -> [Node] {
            var nodes: [Node] = []
            for i in 0 ..< filesCount {
                nodes.append(node(at: i))
            }
            return nodes
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
//            .filter {
//                $0.downloaded >= $0.size
//            }
        }

        var downloadPath: URL {
            guard let downloadPath = torrentHandle.snapshot.downloadPath
            else {
                assertionFailure("downloadPath cannot be nil for this object")
                return URL(string: "/")!
            }

            return downloadPath
        }

        private let torrentHandle: TorrentHandle
        private let rootDirectory: PathNode
        private let keys: [String] 
    }
}
