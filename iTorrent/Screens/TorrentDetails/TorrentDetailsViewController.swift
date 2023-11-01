//
//  TorrentDetailsViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 30/10/2023.
//

import MvvmFoundation
import SwiftUI

class TorrentDetailsViewController<VM: TorrentDetailsViewModel>: BaseViewController<VM> {
    @IBOutlet private var collectionView: MvvmCollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = viewModel.title
        navigationItem.largeTitleDisplayMode = .never

        disposeBag.bind {
            viewModel.$sections.sink { [unowned self] sections in
                if needUpdate(first: collectionView.diffDataSource.snapshot().sectionIdentifiers, second: sections) {
                    collectionView.diffDataSource.applyModels(sections)
                }
            }
        }

        toolbarItems = [
            .init(title: "Start", image: .init(systemName: "play"), primaryAction: .init(handler: { [unowned self] _ in
                viewModel.resume()
            })),
            fixedSpacing,
            .init(title: "Pause", image: .init(systemName: "pause"), primaryAction: .init(handler: { [unowned self] _ in
                viewModel.pause()
            })),
            fixedSpacing,
            .init(title: "Rehash", image: .init(systemName: "arrow.clockwise"), primaryAction: .init(handler: { [unowned self] _ in
                viewModel.rehash()
            })),
            .init(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            .init(title: "Delete", image: .init(systemName: "trash"), primaryAction: .init(handler: { [unowned self] _ in
//                    viewModel.torrentHandle.pause()
            }))
        ]
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        smoothlyDeselectRows(in: collectionView)
    }
}

private extension TorrentDetailsViewController {
    var fixedSpacing: UIBarButtonItem {
        let item = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        item.width = 44
        return item
    }

    func needUpdate(first: [MvvmCollectionSectionModel], second: [MvvmCollectionSectionModel]) -> Bool {
        var needUpdate = false
        let diff = first.difference(from: second)
        if !diff.insertions.isEmpty || !diff.removals.isEmpty {
            needUpdate = true
        }
        if !needUpdate {
            for section in first.enumerated() {
                let diff = section.element.items.difference(from: second[section.offset].items)
                if !diff.insertions.isEmpty || !diff.removals.isEmpty {
                    needUpdate = true
                }
            }
        }
        return needUpdate
    }
}
