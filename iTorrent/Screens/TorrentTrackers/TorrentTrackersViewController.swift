//
//  TorrentTrackersViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 10/11/2023.
//

import MvvmFoundation
import UIKit

class TorrentTrackersViewController<VM: TorrentTrackersViewModel>: BaseViewController<VM> {
    @IBOutlet private var collectionView: MvvmCollectionView!
    private let addButton = UIBarButtonItem(systemItem: .add)
    private let removeButton = UIBarButtonItem()
    private let reannounceButton = UIBarButtonItem()

    override var isToolbarItemsHidden: Bool { false }

    override func viewDidLoad() {
        super.viewDidLoad()

        disposeBag.bind {
            viewModel.$sections.sink { [unowned self] sections in
                collectionView.diffDataSource.applyModels(sections)
            }

            viewModel.isRemoveAvailable.sink { [unowned self] available in
                removeButton.isEnabled = available
            }

            collectionView.$selectedIndexPaths.sink { [unowned self] indexPaths in
                viewModel.selectedIndexPaths = indexPaths
            }

            viewModel.$trackers.map { $0.isEmpty }.sink { [unowned self] isEmpty in
                if #available(iOS 17.0, *) {
                    var config = UIContentUnavailableConfiguration.empty()
                    config.image = .init(systemName: "externaldrive.fill.badge.questionmark")
                    config.text = %"trackers.empty.title" // "No trackers"
                    config.secondaryText = %"trackers.empty.subtitle" // "You can add trackers manually by editing this page"
                    contentUnavailableConfiguration = isEmpty ? config : nil
                }
            }
        }

        title = %"details.actions.trackers"

        navigationItem.trailingItemGroups.append(.fixedGroup(items: [editButtonItem]))
        collectionView.allowsMultipleSelectionDuringEditing = true
        collectionView.allowsSelection = false

//        collectionView.delegate = delegates

        let importActions: [UIAction] = viewModel.trackersListService.trackerSources.value.values.map { [unowned self] source in
            .init(title: source.title) { [unowned self] _ in
                viewModel.addTrackers(from: source)
            }
        }

        addButton.menu = .init(title: %"trackers.add", children: [
            UIAction(title: %"trackers.add.manually") { [unowned self] _ in
                viewModel.addTrackers()
            },
            UIMenu(title: %"trackers.add.fromSource", children: importActions + [
                UIAction(title: %"trackers.add.fromSource.all", image: .init(systemName: "list.bullet")) { [unowned self] _ in
                    viewModel.addAllTrackersFromSourcesList()
                }
            ])
        ])
        removeButton.primaryAction = .init(title: %"trackers.remove", image: .init(systemName: "trash"), handler: { [unowned self] _ in
            viewModel.removeSelected()
        })
        reannounceButton.primaryAction = .init(title: %"trackers.reannounceAll") { [unowned self] _ in
            viewModel.reannounceAll()
        }

        toolbarItems = regularToolbar
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        collectionView.isEditing = editing
        toolbarItems = editing ? editToolbar : regularToolbar
        collectionView.allowsSelection = editing
    }

    private lazy var regularToolbar: [UIBarButtonItem] = {
        [
            .init(systemItem: .flexibleSpace),
            reannounceButton,
            .init(systemItem: .flexibleSpace)
        ]
    }()

    private lazy var editToolbar: [UIBarButtonItem] = {
        [
            //            .init(systemItem: .flexibleSpace),
            addButton,
            .init(systemItem: .flexibleSpace),
            removeButton
//            .init(systemItem: .flexibleSpace)
        ]
    }()
}

private extension TorrentTrackersViewController {}
