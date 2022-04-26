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

class TorrentsListViewController: MvvmTableViewController<TorrentsListViewModel> {
    let editItem = UIBarButtonItem(title: "Edit", style: .plain, target: nil, action: nil)
    let addTorrentItem = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
    let settingsItem = UIBarButtonItem(image: UIImage(systemName: "gearshape.fill"), style: .plain, target: nil, action: nil)
    let spacerItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

    var dataSource: DiffableDataSource<TorrentsListTorrentModel>?

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

        updateEditState(animated: false)
        setupItems()
    }

    override func binding() {
        super.binding()

        bind(in: bag) {
            viewModel.$sections.observeNext { [unowned self] torrents in
                var snapshot = DiffableDataSource<TorrentsListTorrentModel>.Snapshot()
                snapshot.append(torrents)
                dataSource?.apply(snapshot)
            }
            editItem.bindTap { [unowned self] in
                setEditing(!isEditing, animated: true)
                updateEditState(animated: true)
            }
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isEditing { return }
        viewModel.openTorrentDetails(at: indexPath)
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        UISwipeActionsConfiguration(actions: [UIContextualAction(style: .destructive, title: "Delete", handler: { [unowned self] _, _, completion in
            let title = dataSource?.itemIdentifier(for: indexPath)?.torrent.name
            let vc = UIAlertController(title: "Are you sure to remove?", message: title, preferredStyle: .actionSheet)
            vc.addAction(UIAlertAction(title: "Yes and remove files", style: .destructive, handler: { [unowned self] _ in
                viewModel.removeTorrent(at: indexPath, deleteFiles: true)
            }))
            vc.addAction(UIAlertAction(title: "Yes but keep files", style: .default, handler: { [unowned self] _ in
                viewModel.removeTorrent(at: indexPath, deleteFiles: false)
            }))
            vc.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(vc, animated: true)
            completion(true)
        })])
    }
}

private extension TorrentsListViewController {
    func setupItems() {
        addTorrentItem.menu = UIMenu(title: "Add torrent from", options: [], children:
            [UIAction(title: "Files", image: UIImage(systemName: "doc.fill.badge.plus"), handler: { [unowned self] _ in addViaFileSelector() }),
             UIAction(title: "Magnet", image: UIImage(systemName: "link.badge.plus"), handler: { [unowned self] _ in addViaMagnet() }),
             UIAction(title: "URL", image: UIImage(systemName: "link.badge.plus"), handler: { _ in })])
    }

    func addViaFileSelector() {
        let vc = FilesBrowserController.init { [unowned self] fileUrl in
            viewModel.addTorrentFile(with: fileUrl)
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
            guard let url = vc.textFields?.first?.text
            else { return }

            viewModel.addMagnet(with: url)
        }))
        present(vc, animated: true)
    }

    func updateEditState(animated: Bool) {
        editItem.title = isEditing ? "Done" : "Edit"
        editItem.style = isEditing ? .done : .plain

        let defaultItems = [addTorrentItem, spacerItem, settingsItem]
        let editItems = [spacerItem]

        let currentItems = isEditing ? editItems : defaultItems

        setToolbarItems(currentItems, animated: animated)
        navigationItem.setLeftBarButton(editItem, animated: animated)
    }
}
