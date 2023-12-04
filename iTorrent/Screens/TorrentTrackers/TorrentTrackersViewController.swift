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
    private let addButton = UIBarButtonItem(title: "Add Trackers", image: .init(systemName: "plus"))
    private let removeButton = UIBarButtonItem(title: "Remove Trackers", image: .init(systemName: "trash"))

    override var isToolbarItemsHidden: Bool { !isEditing }

    override func viewDidLoad() {
        super.viewDidLoad()

        disposeBag.bind {
            viewModel.$sections.sink { [unowned self] sections in
                collectionView.diffDataSource.applyModels(sections)
            }
        }

        title = "Trackers"
        
        navigationItem.trailingItemGroups.append(.fixedGroup(items: [editButtonItem]))
        collectionView.allowsMultipleSelectionDuringEditing = true

        removeButton.isEnabled = false

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
    }
}
