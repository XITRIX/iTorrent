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

    init(torrentHandle: TorrentSession.Handle, rootDirectory: PathNode?) {
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
        init(torrentHandle: TorrentSession.Handle, rootDirectory: PathNode?) {
            self.torrentHandle = torrentHandle
            let files = torrentHandle.currentSnapshot?.files ?? []
            self.rootDirectory = rootDirectory ?? .generateRoot(rootName: "", files: files)
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
        
        var filesForPreview: [TorrentSession.Handle.Snapshot.FileEntrySnapshot] {
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
            .compactMap { index in
                torrentHandle.currentSnapshot?.files[index]
            }
//            .filter {
//                $0.downloaded >= $0.size
//            }
        }

        var downloadPath: URL {
            guard let downloadPath = torrentHandle.currentSnapshot?.downloadPath
            else {
                assertionFailure("downloadPath cannot be nil for this object")
                return URL(string: "/")!
            }

            return downloadPath
        }

        private let torrentHandle: TorrentSession.Handle
        private let rootDirectory: PathNode
        private let keys: [String] 
    }
}
