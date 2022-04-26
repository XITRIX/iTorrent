//
//  TorrentDetailsController.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 17.04.2022.
//

import MVVMFoundation
import UIKit

class TorrentDetailsController: MvvmTableViewController<TorrentDetailsViewModel> {
    var dataSource: DiffableDataSource<TableCellRepresentable>!

    let playItem = UIBarButtonItem(barButtonSystemItem: .play, target: nil, action: nil)
    let pauseItem = UIBarButtonItem(barButtonSystemItem: .pause, target: nil, action: nil)
    let rehashItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: nil, action: nil)
    let removeItem = UIBarButtonItem(barButtonSystemItem: .trash, target: nil, action: nil)
    let spacerItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

    lazy var torrentControls: [UIBarButtonItem] = [playItem, spacerItem, pauseItem, spacerItem, rehashItem, spacerItem, spacerItem, spacerItem, spacerItem, spacerItem, removeItem]

    deinit {
        print("Deinit!")
    }

    override func setupView() {
        super.setupView()

        navigationItem.largeTitleDisplayMode = .never

        viewModel.sections.flatMap { $0.items }.forEach { $0.registerCell(in: tableView) }
        dataSource = DiffableDataSource<TableCellRepresentable>.init(tableView: tableView, cellProvider: { tableView, indexPath, itemIdentifier in
            itemIdentifier.resolveCell(in: tableView, for: indexPath)
        })
        tableView.dataSource = dataSource
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableView.automaticDimension

        toolbarItems = torrentControls
    }

    override func binding() {
        super.binding()
        bind(in: bag) {
            playItem.bindTap(viewModel.resume)
            pauseItem.bindTap(viewModel.pause)
            viewModel.canResume => playItem.reactive.isEnabled
            viewModel.canPause => pauseItem.reactive.isEnabled
            rehashItem.bindTap { [unowned self] in rehashAction() }
            removeItem.bindTap { [unowned self] in removeAction() }

            viewModel.$sections.observeNext { [unowned self] values in
                var snapshot = DiffableDataSource<TableCellRepresentable>.Snapshot()
                snapshot.append(values)
                dataSource.apply(snapshot)
            }

            tableView.reactive.selectedRowIndexPath.observeNext { [unowned self] indexPath in
                viewModel.sections[indexPath.section].items[indexPath.row].action.send()
            }
        }
    }

    func rehashAction() {
        let alert = UIAlertController(title: "Torrent rehash?", message: "This action will recheck the state of all downloaded files", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Rehash", style: .destructive, handler: { [unowned self] _ in viewModel.rehash() }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    func removeAction() {
        let alert = UIAlertController(title: "Are you shure to remove?", message: title, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Yes and remove files", style: .destructive, handler: { [unowned self] _ in viewModel.removeTorrent(withFiles: true) }))
        alert.addAction(UIAlertAction(title: "Yes but keep files", style: .default, handler: { [unowned self] _ in viewModel.removeTorrent(withFiles: false) }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}
