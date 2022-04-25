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
        dataSource?.defaultRowAnimation = .top

        tableView.register(cell: TorrentsListTorrentCell.self)
        tableView.dataSource = dataSource

        updateEditState(animated: false)

        addTorrentItem.menu = UIMenu(title: "Add torrent from", options: [], children:
            [UIAction(title: "Files", image: UIImage(systemName: "doc.fill.badge.plus"), handler: { [unowned self] _ in
                let vc = FilesBrowserController.init { fileUrl in
                    viewModel.addTorrent(with: fileUrl)
                }
                present(vc, animated: true)
            }),
            UIAction(title: "Magnet", image: UIImage(systemName: "link.badge.plus"), handler: { _ in }),
            UIAction(title: "URL", image: UIImage(systemName: "link.badge.plus"), handler: { _ in })])
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
}

extension TorrentsListViewController {
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
