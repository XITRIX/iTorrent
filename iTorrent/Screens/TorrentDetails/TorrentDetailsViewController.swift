//
//  TorrentDetailsViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 30/10/2023.
//

import Combine
import MvvmFoundation
import SwiftUI

class TorrentDetailsViewController<VM: TorrentDetailsViewModel>: BaseViewController<VM> {
    @IBOutlet private var collectionView: MvvmCollectionView!

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

            viewModel.$sections.sink { [unowned self] sections in
                if collectionView.diffDataSource.snapshot().sectionIdentifiers.differs(from: sections) {
                    collectionView.diffDataSource.applyModels(sections)
                }
            }

            viewModel.shareAvailable.sink { [unowned self] available in
                shareButton.isEnabled = available
            }

            viewModel.$canResume.sink { [unowned self] canResume in
//                if #unavailable(iOS 26) {
                    playButton.isEnabled = canResume
//                }
            }

            viewModel.$canPause.sink { [unowned self] canPause in
//                if #unavailable(iOS 26) {
                    pauseButton.isEnabled = canPause
//                }
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
            viewModel.rehash()
        })

        deleteButton.primaryAction = .init(title: %"common.delete", image: .init(systemName: "trash"), handler: { [unowned self] _ in
            viewModel.removeTorrent()
        })

        shareButton.menu = .init(title: %"common.share", children: [
            UIAction(title: %"details.share.torrentFile", image: .init(systemName: "doc"), handler: { [unowned self] _ in
                guard let path = viewModel.torrentFilePath
                else { return }

                let url = NSURL(fileURLWithPath: path, isDirectory: false)
                let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                if vc.popoverPresentationController != nil {
                    vc.popoverPresentationController?.barButtonItem = shareButton
                    vc.popoverPresentationController?.permittedArrowDirections = .any
                }
                present(vc, animated: true)
            }),
            UIAction(title: %"details.share.magnet", image: .init(systemName: "link"), handler: { [unowned self] _ in
                viewModel.shareMagnet()
            })
        ])
        navigationItem.trailingItemGroups.append(.fixedGroup(items: [shareButton]))

        reloadToolbar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        smoothlyDeselectRows(in: collectionView)
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
    var fixedSpacing: UIBarButtonItem {
        let item = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        item.width = 44
        return item
    }

    func reloadToolbar() {
        if #available(iOS 26, visionOS 99999, *), false {
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
