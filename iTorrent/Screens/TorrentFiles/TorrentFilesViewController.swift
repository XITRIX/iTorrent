//
//  TorrentFilesViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 03/11/2023.
//

import AVKit
import MvvmFoundation
import QuickLook
import UIKit

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
                    parent.openPreview(start: node.index)
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
//        @MainActor
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            parent.viewModel.filesForPreview.count
        }

//        @MainActor
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            let path = parent.viewModel.filesForPreview[index].path
            let res = parent.viewModel.downloadPath.appending(path: path).standardized as NSURL
            return res
        }
    }

    func openPreview(start fileIndex: Int) {
        guard let startIndex = viewModel.filesForPreview.firstIndex(where: { $0.index == fileIndex })
        else { return }

        let path = viewModel.filesForPreview[startIndex].path
        let url = viewModel.downloadPath.appending(path: path)

        Task {
            // Allow to choose be
            guard await checkFilePlayable(url: url) else {
                previewAction(start: startIndex)
                return
            }

            let alert = UIAlertController(title: "Preview mode", message: nil, preferredStyle: .actionSheet)
            alert.addAction(.init(title: "Quick Look preview", style: .default) { [self] _ in
                previewAction(start: startIndex)
            })
            alert.addAction(.init(title: "Media player", style: .default) { [self] _ in
                playerAction(start: startIndex)
            })
            alert.addAction(.init(title: %"common.cancel", style: .cancel))
            present(alert, animated: true)
        }
    }

    func previewAction(start startIndex: Int) {
        let vc = QLPreviewController()
        vc.dataSource = previewDelegates
        vc.currentPreviewItemIndex = startIndex
        present(vc, animated: true)
    }

    func playerAction(start startIndex: Int) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {}

        let path = viewModel.filesForPreview[startIndex].path
        let url = viewModel.downloadPath.appending(path: path)
        let player = AVPlayer(url: url)
        let playerController = AVPlayerViewController.resolve()
        playerController.canStartPictureInPictureAutomaticallyFromInline = true
        playerController.allowsPictureInPicturePlayback = true
        playerController.player = player

        let title = AVMutableMetadataItem()
        title.identifier = .commonIdentifierTitle
        title.value = (url.deletingPathExtension().lastPathComponent) as NSString
        title.extendedLanguageTag = "und"

        let artwork = AVMutableMetadataItem()
        if let imageData = UIImage.icon(forFileURL: url).jpegData(compressionQuality: 1.0) {
            artwork.identifier = .commonIdentifierArtwork
            artwork.value = imageData as NSData
            artwork.dataType = kCMMetadataBaseDataType_JPEG as String
            artwork.extendedLanguageTag = "und"
        }

        // Set external metadata for the current AVPlayerItem
        player.currentItem?.externalMetadata = [title, artwork]

        present(playerController, animated: true)
    }

    func checkFilePlayable(url: URL) async -> Bool {
        let disposeBag = DisposeBag()
        let player = AVPlayer(url: url)

        return await withCheckedContinuation { continuation in
            player.currentItem?.publisher(for: \.status).sink { status in
                guard status != .unknown else { return }
                continuation.resume(returning: status == .readyToPlay)
            }.store(in: disposeBag)
        }
    }
}
