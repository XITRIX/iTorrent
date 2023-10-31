//
//  TorrentListViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 29/10/2023.
//

import CombineCocoa
import LibTorrent
import MvvmFoundation
import SwiftUI
import UIKit

class TorrentListViewController<VM: TorrentListViewModel>: BaseViewController<VM> {
    @IBOutlet private var collectionView: MvvmCollectionView!

    private let addButton = UIBarButtonItem(title: "Add", image: .init(systemName: "plus"))
    private let preferencesButton = UIBarButtonItem(title: "Preferences", image: .init(systemName: "gearshape.fill"))
    private lazy var delegates = Delegates(parent: self)

    private lazy var documentPicker = makeDocumentPicker()

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()

        bind(in: disposeBag) {
            viewModel.$sections.sink { [unowned self] sections in
                collectionView.sections.send(sections)
            }

            addButton.tapPublisher.sink { [unowned self] _ in
                present(documentPicker, animated: true, completion: nil)
            }
        }

        toolbarItems = [addButton, .init(systemItem: .flexibleSpace), preferencesButton]
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        smoothlyDeselectRows(in: collectionView)
    }
}

private extension TorrentListViewController {
    func setup() {
        title = viewModel.title
        navigationItem.largeTitleDisplayMode = .always
        setupCollectionView()
    }

    func setupCollectionView() {

    }
}

extension TorrentListViewController {
    class Delegates: DelegateObject<TorrentListViewController>, UIDocumentPickerDelegate {
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            TorrentService.shared.addTorrent(by: url)
        }
    }

    func makeDocumentPicker() -> UIViewController {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.init(importedAs: "com.bittorrent.torrent")])
        documentPicker.delegate = delegates
        documentPicker.allowsMultipleSelection = false
        documentPicker.shouldShowFileExtensions = true
        return documentPicker
    }
}
