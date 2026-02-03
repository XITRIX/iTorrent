//
//  TorrentFilesFileView.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 12.12.2025.
//

import SwiftUI
import LibTorrent
import Combine
import MvvmFoundation

struct TorrentFilesFileView: View {

    @StateObject var viewModel: ViewModel
    @State private var playerUrl: URL?
//    @State private var file: FileEntry

    init(node: FileNode, viewModel: TorrentFilesView.ViewModel) {
        self._viewModel = .init(wrappedValue: .init(viewModel: viewModel, node: node))
    }

    var body: some View {
        Button {
            playerUrl = viewModel.url
        } label: {
            VStack {
                Text(viewModel.name)
                Text(viewModel.subtitle)
            }
        }
        .buttonStyle(.automatic)
        .focusable()
        .fullScreenCover(item: $playerUrl, content: { url in
            VLCPlayerView(url: url)
        })
    }
}

extension TorrentFilesFileView {
    class ViewModel: ObservableObject {
        private var node: FileNode
        private var viewModel: TorrentFilesView.ViewModel

        @Published var file: FileEntry?
        private let disposeBag = DisposeBag()

        init(viewModel: TorrentFilesView.ViewModel, node: FileNode) {
            self.viewModel = viewModel
            self.node = node

            update()
            disposeBag.bind {
                TorrentService.shared.updateNotifier.sink { [weak self] _ in
                    self?.update()
                }
            }
        }

        var name: String {
            node.name
        }

        var subtitle: String {
            guard let file else { return "Null" }
            let percent = "\(String(format: "%.2f", file.progress * 100))%"
            return "\(file.downloaded.bitrateToHumanReadable) / \(file.size.bitrateToHumanReadable) (\(percent))"
        }

        var url: URL? {
            guard let path = file?.path
            else { return nil }

            return viewModel.downloadPath.appending(path: path)
        }

        func update() {
            guard let startIndex = viewModel.filesForPreview.firstIndex(where: { $0.index == node.index })
            else { return }

            file = viewModel.filesForPreview[startIndex]
        }
    }
}

extension FileEntry {
    var progress: Double {
        Double(downloaded) / Double(size)
    }
}
