//
//  TorrentFilesViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 03/11/2023.
//

import MvvmFoundation
import UIKit

class TorrentFilesViewController<VM: TorrentFilesViewModel>: BaseViewController<VM> {
    @IBOutlet private var collectionView: UICollectionView!

    private lazy var delegates = Deletates(parent: self)

    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.title

        collectionView.register(TorrentFilesDictionaryItemViewCell<TorrentFilesDictionaryItemViewModel>.self, forCellWithReuseIdentifier: TorrentFilesDictionaryItemViewCell<TorrentFilesDictionaryItemViewModel>.reusableId)
        collectionView.register(type: TorrentFilesFileListCell<TorrentFilesFileItemViewModel>.self, hasXib: false)

        collectionView.dataSource = delegates
        collectionView.delegate = delegates
        collectionView.collectionViewLayout = UICollectionViewCompositionalLayout.list(using: .init(appearance: .plain))

        collectionView.allowsMultipleSelectionDuringEditing = true
        navigationItem.trailingItemGroups = [.fixedGroup(items: [editButtonItem])]
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        smoothlyDeselectRows(in: collectionView)
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        collectionView.isEditing = editing
        toolbarItems = editing ?
            [.init(image: .init(systemName: "ellipsis.circle"), menu: .makeForChangePriority { [unowned self] priority in
                viewModel.setPriority(priority, at: collectionView.indexPathsForSelectedItems ?? [])
            })] :
            []
        navigationController?.setToolbarHidden(isToolbarItemsHidden, animated: true)
    }
}

private extension TorrentFilesViewController {
    class Deletates: DelegateObject<TorrentFilesViewController>, UICollectionViewDataSource, UICollectionViewDelegate {
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            parent.viewModel.filesCount
        }

        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let node = parent.viewModel.node(at: indexPath.item)
            switch node {
            case let node as FileNode:
                let cell = collectionView.dequeue(for: indexPath) as TorrentFilesFileListCell<TorrentFilesFileItemViewModel>
                cell.setup(with: parent.viewModel.fileModel(for: node.index))
                return cell
            case let node as PathNode:
                let cell = collectionView.dequeue(for: indexPath) as TorrentFilesDictionaryItemViewCell<TorrentFilesDictionaryItemViewModel>
                cell.prepare(with: parent.viewModel.pathModel(for: node))
                return cell
            default:
                return UICollectionViewCell()
            }
        }

        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            guard !collectionView.isEditing else { return }

            if let cell = collectionView.cellForItem(at: indexPath) as? TorrentFilesFileListCell<TorrentFilesFileItemViewModel> {
                cell.viewModel.selectAction?()
            }

            if parent.viewModel.select(at: indexPath.item) {
                collectionView.deselectItem(at: indexPath, animated: true)
            }
        }
    }
}
