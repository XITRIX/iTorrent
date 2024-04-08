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
    private let addButton = UIBarButtonItem()
    private let removeButton = UIBarButtonItem()

    override var isToolbarItemsHidden: Bool { !isEditing }

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
        }

        title = %"details.actions.trackers"

        navigationItem.trailingItemGroups.append(.fixedGroup(items: [editButtonItem]))
        collectionView.allowsMultipleSelectionDuringEditing = true
        collectionView.allowsSelection = false

//        collectionView.delegate = delegates

        addButton.primaryAction = .init(title: "Add Trackers", image: .init(systemName: "plus"), handler: { [unowned self] _ in
            viewModel.addTrackers()
        })
        removeButton.primaryAction = .init(title: "Remove Trackers", image: .init(systemName: "trash"), handler: { [unowned self] _ in
            viewModel.removeSelected()
        })

        toolbarItems = [
            .init(systemItem: .flexibleSpace),
            addButton,
            .init(systemItem: .flexibleSpace),
            removeButton,
            .init(systemItem: .flexibleSpace)
        ]
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        collectionView.isEditing = editing
        navigationController?.setToolbarHidden(!editing, animated: true)
        collectionView.allowsSelection = editing
    }

//    private lazy var delegates = Delegates(parent: self)
}

private extension TorrentTrackersViewController {
//    class Delegates: DelegateObject<TorrentTrackersViewController>, UICollectionViewDelegate {
//        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//            parent.viewModel.selectingIndexPaths = collectionView.indexPathsForSelectedItems ?? []
//        }
//
//        func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
//            parent.viewModel.selectingIndexPaths = collectionView.indexPathsForSelectedItems ?? []
//        }
//    }
}
