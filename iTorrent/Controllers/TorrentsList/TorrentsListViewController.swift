//
//  TorrentsListViewController.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 28.03.2022.
//

import Bond
import MVVMFoundation
import TorrentKit
import UIKit

class TorrentsListViewController: BaseTableViewController<TorrentsListViewModel> {
    let editItem = UIBarButtonItem(title: "Edit", style: .plain, target: nil, action: nil)
    let selectAllItem = UIBarButtonItem(title: "Select All", style: .plain, target: nil, action: nil)
    let addTorrentItem = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: nil, action: nil)
    let settingsItem = UIBarButtonItem(image: UIImage(systemName: "gearshape.fill"), style: .plain, target: nil, action: nil)
    let spacerItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

    let resumeItem = UIBarButtonItem(barButtonSystemItem: .play, target: nil, action: nil)
    let pauseItem = UIBarButtonItem(barButtonSystemItem: .pause, target: nil, action: nil)
    let rehashItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: nil, action: nil)
    let removeItem = UIBarButtonItem(barButtonSystemItem: .trash, target: nil, action: nil)

    let sortingItem = UIBarButtonItem(image: #imageLiteral(resourceName: "Sort"), style: .plain, target: nil, action: nil)

    var dataSource: DiffableDataSource<TorrentsListTorrentModel>?
    var searchController = UISearchController()

    var firstUpdate: Bool = true

    override class var style: UITableView.Style { .plain }

    override func setupView() {
        super.setupView()
        dataSource = DiffableDataSource<TorrentsListTorrentModel>(tableView: tableView, cellProvider: { tableView, indexPath, model in
            let cell = tableView.dequeue(for: indexPath) as TorrentsListTorrentCell
            cell.setup(with: model)
            return cell
        })

        tableView.register(cell: TorrentsListTorrentCell.self)
        tableView.dataSource = dataSource

        setupSearchController()
        setupSortingItem()
        setupItems()
        updateEditState(animated: false)
    }

    override func binding() {
        super.binding()

        bind(in: bag) {
            viewModel.canResumeAny => resumeItem.reactive.isEnabled
            viewModel.canPauseAny => pauseItem.reactive.isEnabled

            resumeItem.bindTap(viewModel.resumeSelected)
            pauseItem.bindTap(viewModel.pauseSelected)
            rehashItem.bindTap { [unowned self] in
                let message = viewModel.selectedTorrents.map { $0.name }.sorted(by: { $0 < $1 }).joined(separator: "\n")
                let alert = UIAlertController(title: "This action will recheck the state of all downloaded files for torrents:", message: message, preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: "Rehash", style: .destructive, handler: { [unowned self] _ in viewModel.rehashSelected() }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                if alert.popoverPresentationController != nil {
                    alert.popoverPresentationController?.barButtonItem = rehashItem
                    alert.popoverPresentationController?.permittedArrowDirections = .any
                }
                present(alert, animated: true)
            }
            removeItem.bindTap { [unowned self] in
                let message = viewModel.selectedTorrents.map { $0.name }.sorted(by: { $0 < $1 }).joined(separator: "\n")
                let alert = UIAlertController(title: "Are you shure to remove?", message: message, preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: "Yes and remove files", style: .destructive, handler: { [unowned self] _ in viewModel.removeSelected(withFiles: true) }))
                alert.addAction(UIAlertAction(title: "Yes but keep files", style: .default, handler: { [unowned self] _ in viewModel.removeSelected(withFiles: false) }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                if alert.popoverPresentationController != nil {
                    alert.popoverPresentationController?.barButtonItem = removeItem
                    alert.popoverPresentationController?.permittedArrowDirections = .any
                }
                present(alert, animated: true)
            }

            viewModel.$selectedIndexPaths.map { $0.isEmpty ? "Select All" : "Deselect (\($0.count))" } => selectAllItem.reactive.title

            searchController.searchBar.reactive.text => viewModel.$searchQuery
            searchController.searchBar.reactive.cancelTap.observeNext { [unowned self] _ in viewModel.searchQuery = nil }
            viewModel.$sections.observeNext { [unowned self] torrents in
                DispatchQueue.main.async {
                    var snapshot = DiffableDataSource<TorrentsListTorrentModel>.Snapshot()
                    snapshot.append(torrents)
                    dataSource?.apply(snapshot, animatingDifferences: !firstUpdate)
                    refreshSelectedItems()
                    firstUpdate = false
                }
            }
            editItem.bindTap { [unowned self] in
                setEditing(!isEditing, animated: true)
                updateEditState(animated: true)
            }
            selectAllItem.bindTap { [unowned self] in
                let anySelected = tableView.indexPathsForSelectedRows?.count ?? 0 > 0

                if !anySelected {
                    for section in 0..<tableView.numberOfSections {
                        for row in 0..<tableView.numberOfRows(inSection: section) {
                            let indexPath = IndexPath(row: row, section: section)
                            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                            refreshSelectedItems()
                        }
                    }
                } else {
                    tableView.indexPathsForSelectedRows?.forEach {
                        tableView.deselectRow(at: $0, animated: true)
                        refreshSelectedItems()
                    }
                }
            }
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        refreshSelectedItems()
        if isEditing { return }
        viewModel.openTorrentDetails(at: indexPath)
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        refreshSelectedItems()
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        UISwipeActionsConfiguration(actions: [UIContextualAction(style: .destructive, title: "Delete", handler: { [unowned self] _, _, completion in
            let title = dataSource?.itemIdentifier(for: indexPath)?.torrent.name
            let alert = UIAlertController(title: "Are you sure to remove?", message: title, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Yes and remove files", style: .destructive, handler: { [unowned self] _ in
                viewModel.removeTorrent(at: indexPath, deleteFiles: true)
            }))
            alert.addAction(UIAlertAction(title: "Yes but keep files", style: .default, handler: { [unowned self] _ in
                viewModel.removeTorrent(at: indexPath, deleteFiles: false)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            if alert.popoverPresentationController != nil,
                let cell = tableView.cellForRow(at: indexPath) {
                alert.popoverPresentationController?.sourceView = cell
                alert.popoverPresentationController?.sourceRect = cell.bounds
                alert.popoverPresentationController?.permittedArrowDirections = .left
            }

            present(alert, animated: true)
            completion(true)
        })])
    }

    override func tableView(_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        true
    }

    override func tableView(_ tableView: UITableView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        setEditing(true, animated: true)
        updateEditState(animated: true)
    }
}

private extension TorrentsListViewController {
    func setupSearchController() {
        navigationItem.searchController = searchController
        searchController.searchBar.placeholder = "Search"
    }

    func setupSortingItem() {
        let nameSort = UIAction(title: "Name", attributes: []) { [unowned self] _ in
            if viewModel.sortingType.type == .name {
                viewModel.sortingType.reversed.toggle()
            } else {
                viewModel.sortingType = .init(type: .name, reversed: false)
            }
            setupSortingItem()
        }
        if viewModel.sortingType.type == .name { nameSort.image = getSortingArrowImage() }

        let dateAddedSort = UIAction(title: "Date Added", attributes: []) { [unowned self] _ in
            if viewModel.sortingType.type == .dateAdded {
                viewModel.sortingType.reversed.toggle()
            } else {
                viewModel.sortingType = .init(type: .dateAdded, reversed: false)
            }
            setupSortingItem()
        }
        if viewModel.sortingType.type == .dateAdded { dateAddedSort.image = getSortingArrowImage() }

        let dateCreatedSort = UIAction(title: "Date Created", attributes: []) { [unowned self] _ in
            if viewModel.sortingType.type == .dateCreated {
                viewModel.sortingType.reversed.toggle()
            } else {
                viewModel.sortingType = .init(type: .dateCreated, reversed: false)
            }
            setupSortingItem()
        }
        if viewModel.sortingType.type == .dateCreated { dateCreatedSort.image = getSortingArrowImage() }

        let sizeSort = UIAction(title: "Size", attributes: []) { [unowned self] _ in
            if viewModel.sortingType.type == .size {
                viewModel.sortingType.reversed.toggle()
            } else {
                viewModel.sortingType = .init(type: .size, reversed: false)
            }
            setupSortingItem()
        }
        if viewModel.sortingType.type == .size { sizeSort.image = getSortingArrowImage() }

        let menu = UIMenu(title: "Sort torrents by:", options: [], children: [nameSort, dateAddedSort, dateCreatedSort, sizeSort])
        sortingItem.menu = menu
    }

    func getSortingArrowImage() -> UIImage? {
        viewModel.sortingType.reversed ? UIImage(systemName: "chevron.up") : UIImage(systemName: "chevron.down")
    }

    func refreshSelectedItems() {
        guard isEditing else { return }
        viewModel.selectedIndexPaths = tableView.indexPathsForSelectedRows ?? []
    }

    func updateEditState(animated: Bool) {
        editItem.title = isEditing ? "Done" : "Edit"
        editItem.style = isEditing ? .done : .plain

        let defaultItems = [addTorrentItem, spacerItem, settingsItem]
        let editItems = [resumeItem, spacerItem, pauseItem, spacerItem, rehashItem, spacerItem, spacerItem, spacerItem, spacerItem, removeItem]
        let currentItems = isEditing ? editItems : defaultItems

        let defaultRightItems = [sortingItem]
        let editRightItems = [selectAllItem]
        let currentRightItems = isEditing ? editRightItems : defaultRightItems

        setToolbarItems(currentItems, animated: animated)
        navigationItem.setRightBarButtonItems(currentRightItems, animated: animated)
        navigationItem.setLeftBarButton(editItem, animated: animated)

        refreshSelectedItems()
    }
}

// Add torrents variants
private extension TorrentsListViewController {
    func setupItems() {
        addTorrentItem.menu = UIMenu(title: "Add torrent from", options: [], children:
            [UIAction(title: "Files", image: UIImage(systemName: "doc.fill.badge.plus"), handler: { [unowned self] _ in addViaFile() }),
             UIAction(title: "Magnet", image: UIImage(systemName: "link.badge.plus"), handler: { [unowned self] _ in addViaMagnet() }),
             UIAction(title: "URL", image: UIImage(systemName: "link.badge.plus"), handler: { [unowned self] _ in addViaUrl() })])
    }

    func addViaFile() {
        let vc = FilesBrowserController.init { [unowned self] fileUrl in
            if fileUrl.startAccessingSecurityScopedResource() {
                guard let torrent = TorrentFile(with: fileUrl)
                else { return showError(with: "Torrent file is corrupted!") }

                fileUrl.stopAccessingSecurityScopedResource()
                viewModel.addTorrentFile(torrent)
            }
        }
        present(vc, animated: true)
    }

    func addViaMagnet() {
        let vc = UIAlertController(title: "Add from magnet", message: "Please enter the magnet link below", preferredStyle: .alert)
        vc.addTextField { textField in
            textField.placeholder = "magnet:"
        }
        vc.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        vc.addAction(UIAlertAction(title: "OK", style: .default, handler: { [unowned self, unowned vc] _ in
            guard let link = vc.textFields?.first?.text,
                  let url = URL(string: link),
                  let magnet = MagnetURI(with: url)
            else { return showError(with: "Wrong magnet link, check it and try again!") }

            viewModel.addMagnet(with: magnet)
        }))
        present(vc, animated: true)
    }

    func addViaUrl() {
        let vc = UIAlertController(title: "Add from URL", message: "Please enter the existing torrent's URL below", preferredStyle: .alert)
        vc.addTextField { textField in
            textField.placeholder = "https://"
        }
        vc.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        vc.addAction(UIAlertAction(title: "OK", style: .default, handler: { [unowned self, unowned vc] _ in
            guard let path = vc.textFields?.first?.text,
                  let url = URL(string: path)
            else { return showError(with: "Link corrupted or torrent file is unreachable!") }

            let urlRequest = URLRequest(url: url)
            let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
                DispatchQueue.main.async {
                    guard error == nil,
                          let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200,
                          let data = data,
                          let torrent = TorrentFile(with: data)
                    else { return showError(with: "Link corrupted or torrent file is unreachable!") }

                    viewModel.addTorrentFile(torrent)
                }
            }
            task.resume()
        }))
        present(vc, animated: true)
    }

    func showError(with text: String) {
        let vc = UIAlertController(title: "Error", message: text, preferredStyle: .alert)
        vc.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(vc, animated: true)
    }
}
