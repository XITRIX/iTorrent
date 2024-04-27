//
//  BaseCollectionViewController.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 08.04.2024.
//

import MvvmFoundation
import UIKit

class BaseCollectionViewController<VM: BaseCollectionViewModel>: BaseViewController<VM> {
    var collectionView: MvvmCollectionView! { view as? MvvmCollectionView }

    override func loadView() {
        view = MvvmCollectionView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dragInteractionEnabled = true

#if os(visionOS)
        view.backgroundColor = .secondarySystemBackground
#else
        view.backgroundColor = .systemGroupedBackground
        collectionView.keyboardDismissMode = .interactive
#endif

        refresh.addAction(.init { [unowned self] _ in
            Task {
                await refreshTask?()
                refresh.endRefreshing()
            }
        }, for: .valueChanged)

        disposeBag.bind {
            viewModel.$sections.sink { [unowned self] sections in
                collectionView.sections.send(sections)
            }

            collectionView.$selectedIndexPaths.sink { [unowned self] indexPaths in
                viewModel.selectedIndexPaths = indexPaths
            }

            viewModel.$trailingSwipeActionsConfigurationProvider.sink { [unowned self] provider in
                collectionView.diffDataSource.trailingSwipeActionsConfigurationProvider = provider
            }


            viewModel.$refreshTask.sink { [unowned self] refreshTask in
                self.refreshTask = refreshTask

                guard refreshTask != nil else {
                    collectionView.refreshControl = nil
                    return
                }

                collectionView.refreshControl = refresh
            }

            viewModel.dismissSelection.sink { [unowned self] _ in
                collectionView.diffDataSource.deselectItems()
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        smoothlyDeselectRows(in: collectionView)
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        collectionView.isEditing = editing
    }

    private var refreshTask: (() async -> Void)?
    private let refresh = UIRefreshControl()
}
