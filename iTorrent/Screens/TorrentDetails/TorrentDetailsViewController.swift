//
//  TorrentDetailsViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 30/10/2023.
//

import Combine
import Foundation
import MvvmFoundation
import SwiftUI

class TorrentDetailsViewController<VM: TorrentDetailsViewModel>: BaseCollectionViewController<VM> {
    private let shareButton = UIBarButtonItem(title: %"common.share", image: .init(systemName: "square.and.arrow.up"))
    private let playButton = UIBarButtonItem()
    private let pauseButton = UIBarButtonItem()
    private let rehashButton = UIBarButtonItem()
    private let deleteButton = UIBarButtonItem()

    override var useMarqueeLabel: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = viewModel.title
        navigationItem.largeTitleDisplayMode = .never

        disposeBag.bind {
            viewModel.dismissSignal.sink { [unowned self] _ in
                guard !((splitViewController as? BaseSplitViewController)?.showEmptyDetail() ?? false)
                else { return }

                pop(animated: true, sender: self)
            }

            viewModel.shareAvailable.sink { [unowned self] available in
                shareButton.isEnabled = available
            }

            viewModel.$canResume.sink { [unowned self] canResume in
                if #unavailable(iOS 26) {
                    playButton.isEnabled = canResume
                }
            }

            viewModel.$canPause.sink { [unowned self] canPause in
                if #unavailable(iOS 26) {
                    pauseButton.isEnabled = canPause
                }
            }

            Publishers.CombineLatest(viewModel.$canResume, viewModel.$canPause)
                .debounce(for: .milliseconds(1), scheduler: UIScheduler.shared)
                .sink { [unowned self] _, _ in
                    reloadToolbar()
                }
        }

        playButton.primaryAction = .init(title: %"details.start", image: .init(systemName: "play.fill"), handler: { [unowned self] _ in
            viewModel.resume()
        })

        pauseButton.primaryAction = .init(title: %"details.pause", image: .init(systemName: "pause.fill"), handler: { [unowned self] _ in
            viewModel.pause()
        })

        rehashButton.primaryAction = .init(title: %"details.rehash", image: .init(systemName: "arrow.clockwise"), handler: { [unowned self] _ in
            viewModel.rehash(from: .barItem(rehashButton))
        })

        deleteButton.primaryAction = .init(title: %"common.delete", image: .init(systemName: "trash"), handler: { [unowned self] _ in
            viewModel.removeTorrent(from: .barItem(deleteButton))
        })

        shareButton.menu = .init(title: %"common.share", children: [
            UIAction(title: %"details.share.torrentFile", image: .init(systemName: "doc"), handler: { [unowned self] _ in
                shareTorrentFile()
            }),
            UIAction(title: %"details.share.magnet", image: .init(systemName: "link"), handler: { [unowned self] _ in
                viewModel.shareMagnet()
            })
        ])
        navigationItem.trailingItemGroups = [.fixedGroup(items: [shareButton])]

        reloadToolbar()
    }
}

extension Array where Element == MvvmCollectionSectionModel {
    func differs(from sections: [MvvmCollectionSectionModel]) -> Bool {
        var needUpdate = false
        let diff = difference(from: sections)
        if !diff.insertions.isEmpty || !diff.removals.isEmpty {
            needUpdate = true
        }
        if !needUpdate {
            for section in enumerated() {
                let diff = section.element.items.difference(from: sections[section.offset].items)
                if !diff.insertions.isEmpty || !diff.removals.isEmpty {
                    needUpdate = true
                }
            }
        }
        return needUpdate
    }
}

private extension TorrentDetailsViewController {
    func shareTorrentFile() {
        guard let sourcePath = viewModel.torrentFilePath else { return }

        var temporaryDirectory: URL?
        do {
            let fileManager = FileManager.default
            let shareDirectory = fileManager.temporaryDirectory
                .appendingPathComponent(UUID().uuidString, isDirectory: true)
            temporaryDirectory = shareDirectory
            try fileManager.createDirectory(at: shareDirectory, withIntermediateDirectories: true)

            let fileName = sanitizedTorrentFileName(from: viewModel.title)
            let shareURL = shareDirectory.appendingPathComponent(fileName, isDirectory: false)
            try fileManager.copyItem(at: URL(fileURLWithPath: sourcePath), to: shareURL)

            let controller = UIActivityViewController(activityItems: [shareURL], applicationActivities: nil)
            controller.completionWithItemsHandler = { _, _, _, _ in
                try? fileManager.removeItem(at: shareDirectory)
            }
            controller.popoverPresentationController?.barButtonItem = shareButton
            controller.popoverPresentationController?.permittedArrowDirections = .any
            present(controller, animated: true)
        } catch {
            if let temporaryDirectory {
                try? FileManager.default.removeItem(at: temporaryDirectory)
            }
            let alert = UIAlertController(title: %"common.error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(.init(title: %"common.close", style: .cancel))
            present(alert, animated: true)
        }
    }

    func sanitizedTorrentFileName(from torrentName: String) -> String {
        var name = torrentName
        if name.lowercased().hasSuffix(".torrent") {
            name.removeLast(".torrent".count)
        }

        let forbiddenCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>:")
            .union(.controlCharacters)
            .union(.newlines)
        name = name.components(separatedBy: forbiddenCharacters).joined(separator: "_")
        name = name.trimmingCharacters(in: .whitespacesAndNewlines.union(.init(charactersIn: ".")))

        while name.utf8.count > 200 {
            name.removeLast()
        }
        name = name.trimmingCharacters(in: .whitespacesAndNewlines.union(.init(charactersIn: ".")))
        if name.isEmpty {
            name = "Torrent"
        }

        return name + ".torrent"
    }

    var fixedSpacing: UIBarButtonItem {
        let item = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        item.width = 44
        return item
    }

    func reloadToolbar() {
        if #available(iOS 26, visionOS 99999, *) {
            toolbarItems = [
                viewModel.canResume ? playButton : nil,
                viewModel.canPause ? pauseButton : nil,
                rehashButton,
                .init(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                deleteButton
            ].compactMap { $0 }
        } else {
            toolbarItems = [
                playButton,
                fixedSpacing,
                pauseButton,
                fixedSpacing,
                rehashButton,
                .init(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                deleteButton
            ]
        }
    }
}
