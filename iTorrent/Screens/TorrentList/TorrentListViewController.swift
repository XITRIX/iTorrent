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

    private let addButton = UIBarButtonItem(title: String(localized: "common.add"), image: .init(systemName: "plus"))
    private let preferencesButton = UIBarButtonItem(title: String(localized: "preferences"), image: .init(systemName: "gearshape.fill"))
    private let sortButton = UIBarButtonItem(title: String(localized: "list.sort"), image: .sort)
    private lazy var delegates = Delegates(parent: self)
    private let searchVC = UISearchController()

    private lazy var documentPicker = makeDocumentPicker()

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()

        searchVC.searchBar.textDidChangePublisher.assign(to: &viewModel.$searchQuery)
        searchVC.searchBar.cancelButtonClickedPublisher.map { "" }.assign(to: &viewModel.$searchQuery)

        addButton.menu = UIMenu(title: String(localized: "list.add.title"), children: [
            UIAction(title: String(localized: "list.add.files"), image: .init(systemName: "doc.fill.badge.plus")) { [unowned self] _ in
                present(documentPicker, animated: true)
            },
            UIAction(title: String(localized: "list.add.magnet"), image: .init(systemName: "link.badge.plus")) { [unowned self] _ in
                present(makeMagnetAlert(), animated: true)
            }
        ])

        disposeBag.bind {
            viewModel.$sections.sink { [unowned self] sections in
                collectionView.sections.send(sections)
            }

            preferencesButton.tapPublisher.sink { [unowned self] _ in
                viewModel.preferencesAction()
            }

            viewModel.sortingType.combineLatest(viewModel.sortingReverced).sink { [unowned self] type, reverced in
                updateSortingMenu(with: type, reverced: reverced)
            }
        }

        navigationItem.leadingItemGroups.append(.fixedGroup(items: [editButtonItem]))
        navigationItem.trailingItemGroups.append(.fixedGroup(items: [sortButton]))
        toolbarItems = [addButton, .init(systemItem: .flexibleSpace), preferencesButton]
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        smoothlyDeselectRows(in: collectionView)
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        collectionView.isEditing = editing
//        collectionView.setEditing(editing, animated: animated)
    }
}

private extension TorrentListViewController {
    func setup() {
        title = viewModel.title
        navigationItem.largeTitleDisplayMode = .always
        setupCollectionView()
        setupSearch()
    }

    func setupCollectionView() {
        collectionView.allowsMultipleSelectionDuringEditing = true
    }

    func setupSearch() {
        searchVC.showsSearchResultsController = false
        searchVC.searchBar.placeholder = String(localized: "common.search")
        navigationItem.searchController = searchVC
    }

    func updateSortingMenu(with selected: ViewModel.Sort, reverced: Bool) {
        sortButton.menu = .init(title: String(localized: "list.sort.title"), children:
            ViewModel.Sort.allCases.map { type in UIAction(title: type.name, image: selected == type ? (reverced ? .init(systemName: "chevron.up") : .init(systemName: "chevron.down")) : nil) { [unowned self] _ in
                if viewModel.sortingType.value == type {
                    viewModel.sortingReverced.value.toggle()
                } else {
                    viewModel.sortingType.value = type
                    viewModel.sortingReverced.value = false
                }
            }})
    }
}

extension TorrentListViewController {
    class Delegates: DelegateObject<TorrentListViewController>, UIDocumentPickerDelegate {
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.viewModel.addTorrent(by: url)
        }
    }

    func makeDocumentPicker() -> UIViewController {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.init(importedAs: "com.bittorrent.torrent")])
        documentPicker.delegate = delegates
        documentPicker.allowsMultipleSelection = false
        documentPicker.shouldShowFileExtensions = true
        return documentPicker
    }

    func makeMagnetAlert() -> UIAlertController {
        let alert = UIAlertController(title: String(localized: "list.add.magnet.title"), message: String(localized: "list.add.magnet.message"), preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = String(localized: "list.add.magnet.placeholder")
        }

        alert.addAction(.init(title: String(localized: "common.cancel"), style: .cancel))
        alert.addAction(.init(title: String(localized: "common.ok"), style: .default) { [unowned self] _ in
            guard let text = alert.textFields?.first?.text,
                  let url = URL(string: text),
                  let magnet = MagnetURI(with: url)
            else {
                let alert = UIAlertController(title: String(localized: "common.error"), message: String(localized: "list.add.magnet.error"), preferredStyle: .alert)
                alert.addAction(.init(title: String(localized: "common.close"), style: .cancel))
                present(alert, animated: true)
                return
            }
            TorrentService.shared.addTorrent(by: magnet)
        })
        return alert
    }
}

private extension TorrentListViewModel.Sort {
    var name: String {
        switch self {
        case .alphabetically:
            return String(localized: "list.sort.name")
        case .creationDate:
            return String(localized: "list.sort.creationDate")
        case .addedDate:
            return String(localized: "list.sort.addedDate")
        case .size:
            return String(localized: "list.sort.size")
        }
    }
}
