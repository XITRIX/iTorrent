//
//  PreferencesSectionGroupingViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 04/04/2024.
//

import UIKit

class PreferencesSectionGroupingViewController<VM: PreferencesSectionGroupingViewModel>: BasePreferencesViewController<VM> {
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.isEditing = true
        collectionView.dragInteractionEnabled = true

        navigationItem.trailingItemGroups = [.fixedGroup(items: [.init(primaryAction: .init(title: %"common.reset", handler: { [unowned self] _ in
            viewModel.resetAction()
        }))])]

        disposeBag.bind {
            collectionView.diffDataSource.didReorderCells.sink { [unowned self] changes in
                viewModel.didMoved(with: changes.finalSnapshot)
            }
        }
    }
}
