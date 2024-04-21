//
//  TorrentFilesViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 03/11/2023.
//

import MvvmFoundation
import UIKit
import QuickLook

class TorrentFilesViewController<VM: TorrentFilesViewModel>: BaseViewController<VM> {
    @IBOutlet private var collectionView: UICollectionView!

    private lazy var collectionDelegates = CollectionDeletates(parent: self)
    private lazy var previewDelegates = PreviewDeletates(parent: self)
    private let moreMenuButton = UIBarButtonItem()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.title

        collectionView.register(TorrentFilesDictionaryItemViewCell<TorrentFilesDictionaryItemViewModel>.self, forCellWithReuseIdentifier: TorrentFilesDictionaryItemViewCell<TorrentFilesDictionaryItemViewModel>.reusableId)
        collectionView.register(type: TorrentFilesFileListCell<TorrentFilesFileItemViewModel>.self, hasXib: false)

        collectionView.dataSource = collectionDelegates
        collectionView.delegate = collectionDelegates
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

        reloadMoreMenuButton()
        toolbarItems = editing ?
            [moreMenuButton] :
            []
        navigationController?.setToolbarHidden(isToolbarItemsHidden, animated: true)
    }
}

private extension TorrentFilesViewController {
    func reloadMoreMenuButton() {
        moreMenuButton.isEnabled = !collectionView.indexPathsForSelectedItems.isNilOrEmpty

        let priorityMenu = UIMenu.makeForChangePriority(options: [.displayInline]) { [unowned self] priority in
            viewModel.setPriority(priority, at: collectionView.indexPathsForSelectedItems ?? [])
        }

        let shareAction = UIAction(title: %"common.share", image: .init(systemName: "square.and.arrow.up")) { [unowned self] _ in
            viewModel.shareSelected(collectionView.indexPathsForSelectedItems ?? [])
        }

        var menuElements: [UIMenuElement] = []

        if viewModel.canChangePriorityForSelected(collectionView.indexPathsForSelectedItems ?? []) {
            menuElements.append(priorityMenu)
        }

        if viewModel.canShareSelected(collectionView.indexPathsForSelectedItems ?? []) {
            guard !menuElements.isEmpty else {
                moreMenuButton.menu = nil
                moreMenuButton.primaryAction = shareAction
                return
            }
            menuElements.append(shareAction)
        }

        let menu = UIMenu(children: menuElements)

        moreMenuButton.menu = menu
        moreMenuButton.primaryAction = nil
        moreMenuButton.image = .init(systemName: "ellipsis.circle")
    }
}

private extension TorrentFilesViewController {
    class CollectionDeletates: DelegateObject<TorrentFilesViewController>, UICollectionViewDataSource, UICollectionViewDelegate {
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            parent.viewModel.filesCount
        }

        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let node = parent.viewModel.node(at: indexPath.item)
            switch node {
            case let node as FileNode:
                let cell = collectionView.dequeue(for: indexPath) as TorrentFilesFileListCell<TorrentFilesFileItemViewModel>
                let vm = parent.viewModel.fileModel(for: node.index)
                vm.previewAction = { [unowned self] in
                    parent.previewAction(start: node.index)
                }
                cell.setup(with: vm)
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
            guard !collectionView.isEditing else {
                return parent.reloadMoreMenuButton()
            }

            if let cell = collectionView.cellForItem(at: indexPath) as? TorrentFilesFileListCell<TorrentFilesFileItemViewModel> {
                cell.viewModel.selectAction?()
            }

            if parent.viewModel.select(at: indexPath.item) {
                collectionView.deselectItem(at: indexPath, animated: true)
            }
        }

        func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
            parent.reloadMoreMenuButton()
        }
    }

    class PreviewDeletates: DelegateObject<TorrentFilesViewController>, QLPreviewControllerDataSource {
        @MainActor
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            parent.viewModel.filesForPreview.count
        }

        @MainActor
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            let path = parent.viewModel.filesForPreview[index].path
            return TorrentService.downloadPath.appending(path: path) as NSURL
        }
    }

    func previewAction(start fileIndex: Int) {
        guard let startIndex = viewModel.filesForPreview.firstIndex(where: { $0.index == fileIndex })
        else { return }

        let vc = QLPreviewController()
        vc.dataSource = previewDelegates
        vc.currentPreviewItemIndex = startIndex
        present(vc, animated: true)
    }
}
