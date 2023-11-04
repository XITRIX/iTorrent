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
    private let sortButton = UIBarButtonItem(title: "Sorting", image: .sort)
    private lazy var delegates = Delegates(parent: self)
    private let searchVC = UISearchController()

    private lazy var documentPicker = makeDocumentPicker()

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()

        searchVC.searchBar.textDidChangePublisher.assign(to: &viewModel.$searchQuery)
        searchVC.searchBar.cancelButtonClickedPublisher.map { "" }.assign(to: &viewModel.$searchQuery)

        disposeBag.bind {
            viewModel.$sections.sink { [unowned self] sections in
                collectionView.sections.send(sections)
            }

            addButton.tapPublisher.sink { [unowned self] _ in
                present(documentPicker, animated: true, completion: nil)
            }

            viewModel.$sortingType.combineLatest(viewModel.$sortingReverced).sink { [unowned self] type, reverced in
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
        searchVC.searchBar.placeholder = "Search"
        navigationItem.searchController = searchVC
    }

    func updateSortingMenu(with selected: ViewModel.Sort, reverced: Bool) {
        sortButton.menu = .init(title: "Sort torrents by:", children:
            ViewModel.Sort.allCases.map { type in UIAction(title: type.name, image: selected == type ? (reverced ? .init(systemName: "chevron.up") : .init(systemName: "chevron.down")) : nil) { [unowned self] _ in
                if viewModel.sortingType == type {
                    viewModel.sortingReverced.toggle()
                } else {
                    viewModel.sortingType = type
                    viewModel.sortingReverced = false
                }
            }})
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

private extension TorrentListViewModel.Sort {
    var name: String {
        switch self {
        case .alphabetically:
            return "Name"
        case .creationDate:
            return "Date Created"
        case .size:
            return "Size"
        }
    }
}