//
//  TorrentAddViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 06/11/2023.
//

import MvvmFoundation
import UIKit

class TorrentAddViewController<VM: TorrentAddViewModel>: BaseViewController<VM> {
    @IBOutlet private var collectionView: UICollectionView!
    private lazy var delegates = Deletates(parent: self)
    private let cancelButton = UIBarButtonItem(systemItem: .close)
    private let downloadButton = UIBarButtonItem(title: "Download", style: .done, target: nil, action: nil)
    private let diskLabel = makeDiskLabel()
    private let moreButton = UIBarButtonItem(title: "More", image: .init(systemName: "ellipsis.circle"))

    override func viewDidLoad() {
        super.viewDidLoad()
        title = viewModel.title

        moreButton.menu = makeMoreMenu()

        collectionView.register(TorrentFilesDictionaryItemViewCell<TorrentAddDirectoryItemViewModel>.self, forCellWithReuseIdentifier: TorrentFilesDictionaryItemViewCell<TorrentAddDirectoryItemViewModel>.reusableId)
        collectionView.register(type: TorrentFilesFileListCell<TorrentAddFileItemViewModel>.self, hasXib: false)

        collectionView.dataSource = delegates
        collectionView.delegate = delegates
        collectionView.collectionViewLayout = UICollectionViewCompositionalLayout.list(using: .init(appearance: .plain))

        if viewModel.isRoot {
            navigationController?.isModalInPresentation = true
            navigationController?.presentationController?.delegate = delegates

            navigationItem.leadingItemGroups.append(.fixedGroup(items: [cancelButton]))
        }

        navigationItem.trailingItemGroups.append(.fixedGroup(items: [downloadButton]))

        navigationController?.setToolbarHidden(false, animated: false)
        toolbarItems = [
            .init(customView: diskLabel),
            .init(systemItem: .flexibleSpace),
            moreButton
        ]

        disposeBag.bind {
            cancelButton.tapPublisher.sink { [unowned self] _ in
                viewModel.cancel()
            }
            downloadButton.tapPublisher.sink { [unowned self] _ in
                viewModel.download()
            }
            viewModel.diskTextPublisher.sink { [unowned self] text in
                diskLabel.text = text
                diskLabel.sizeToFit()
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        smoothlyDeselectRows(in: collectionView)
    }
}

private extension TorrentAddViewController {
    static func makeDiskLabel() -> UILabel {
        let label = UILabel()
        label.textColor = .secondaryLabel
        label.font = .preferredFont(forTextStyle: .callout)
        return label
    }

    func makeMoreMenu() -> UIMenu {
        .init(children: [
            UIAction(title: "files.selectAll", image: .init(systemName: "checkmark.circle"), handler: { [unowned self] _ in
                viewModel.selectAll()
            }),
            UIAction(title: "files.deselectAll", image: .init(systemName: "xmark.circle"), attributes: [.destructive], handler: { [unowned self] _ in
                viewModel.deselectAll()
            })
        ])
    }
}

private extension TorrentAddViewController {
    class Deletates: DelegateObject<TorrentAddViewController>, UICollectionViewDataSource, UICollectionViewDelegate, UIAdaptivePresentationControllerDelegate {
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            parent.viewModel.filesCount
        }

        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let node = parent.viewModel.node(at: indexPath.item)
            switch node {
            case let node as FileNode:
                let cell = collectionView.dequeue(for: indexPath) as TorrentFilesFileListCell<TorrentAddFileItemViewModel>
                cell.setup(with: parent.viewModel.fileModel(for: node.index))
                cell.disposeBag.bind { [unowned self] in
                    parent.viewModel.updatePublisher.sink { [weak cell] _ in
                        cell?.viewModel.localUpdatePublisher.send(.init())
                    }
                }
                return cell
            case let node as PathNode:
                let cell = collectionView.dequeue(for: indexPath) as TorrentFilesDictionaryItemViewCell<TorrentAddDirectoryItemViewModel>
                cell.prepare(with: parent.viewModel.pathModel(for: node))
                cell.disposeBag.bind { [unowned self] in
                    parent.viewModel.updatePublisher.sink { [weak cell] _ in
                        cell?.model.localUpdatePublisher.send(.init())
                    }
                }
                return cell
            default:
                return UICollectionViewCell()
            }
        }

        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            if let cell = collectionView.cellForItem(at: indexPath) as? TorrentFilesFileListCell<TorrentAddFileItemViewModel> {
                cell.viewModel.selectAction?()
            }

            if parent.viewModel.select(at: indexPath.item) {
                collectionView.deselectItem(at: indexPath, animated: true)
            }
        }

        func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
            let alert = UIAlertController(title: "Are you sure to dismiss?", message: "All changes will be lost", preferredStyle: .alert)
            alert.addAction(.init(title: "Cancel", style: .cancel))
            alert.addAction(.init(title: "Dismiss", style: .destructive, handler: { [unowned self] _ in
                parent.viewModel.dismiss()
            }))
            parent.navigationController?.present(alert, animated: true)
        }
    }
}
