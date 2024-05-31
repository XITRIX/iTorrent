//
//  RssListViewController.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 08.04.2024.
//

import MvvmFoundation
import UIKit

class RssListViewController<VM: RssListViewModel>: BaseCollectionViewController<VM> {
    private let addButton = UIBarButtonItem()
    private let removeButton = UIBarButtonItem()

    override var isToolbarItemsHidden: Bool { !isEditing }

    override func viewDidLoad() {
        super.viewDidLoad()

#if os(visionOS)
        view.backgroundColor = .secondarySystemBackground
#endif

        disposeBag.bind {
            viewModel.$sections.sink { [unowned self] sections in
                collectionView.diffDataSource.applyModels(sections)
            }

            viewModel.isRemoveAvailable.sink { [unowned self] available in
                removeButton.isEnabled = available
            }

//            collectionView.$selectedIndexPaths.sink { [unowned self] indexPaths in
//                viewModel.selectedIndexPaths = indexPaths
//            }

            collectionView.diffDataSource.didReorderCells.sink { [unowned self] transaction in
                guard let firstSection = transaction.finalSnapshot.sectionIdentifiers.first
                else { return }

                viewModel.reorderItems(transaction.finalSnapshot.itemIdentifiers(inSection: firstSection).map { $0.viewModel })
            }

            viewModel.isEmpty.sink { [unowned self] isEmpty in
                if #available(iOS 17.0, *) {
                    var config = UIContentUnavailableConfiguration.empty()
                    config.image = .icRss
                    config.text = %"rssSearch.empty.title"
                    config.secondaryText = %"rssfeed.empty.subtitle"
                    contentUnavailableConfiguration = isEmpty ? config : nil
                }
            }
        }

        title = %"rssfeed"

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.trailingItemGroups = [.fixedGroup(items: [editButtonItem])]

        collectionView.allowsMultipleSelectionDuringEditing = true

        addButton.primaryAction = .init(title: %"rsslist.add.title", image: .init(systemName: "plus"), handler: { [unowned self] _ in
            viewModel.addFeed()
        })
        removeButton.primaryAction = .init(title: %"rsslist.remove.title", image: .init(systemName: "trash"), handler: { [unowned self] _ in
            viewModel.removeSelected()
        })
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        smoothlyDeselectRows(in: collectionView)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        toolbarItems = editing ?
            [
                .init(systemItem: .flexibleSpace),
                addButton,
                .init(systemItem: .flexibleSpace),
                removeButton,
                .init(systemItem: .flexibleSpace)
            ] : []
        navigationController?.setToolbarHidden(isToolbarItemsHidden, animated: true)
    }
}
