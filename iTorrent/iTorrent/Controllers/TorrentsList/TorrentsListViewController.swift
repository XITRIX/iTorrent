//
//  TorrentsListViewController.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 28.03.2022.
//

import UIKit
import MVVMFoundation
import TorrentKit
import Bond

class TorrentsListViewController: MvvmTableViewController<TorrentsListViewModel> {
    var dataSource: DiffableDataSource<TorrentsListTorrentModel>?

    override class var style: UITableView.Style { .plain }

    override func setupView() {
        super.setupView()
        dataSource = DiffableDataSource<TorrentsListTorrentModel>(tableView: tableView, cellProvider: { tableView, indexPath, torrent in
            let cell = tableView.dequeue(for: indexPath) as TorrentsListTorrentCell
            cell.setup(with: torrent)
            return cell
        })

        tableView.register(cell: TorrentsListTorrentCell.self)
        tableView.dataSource = dataSource
    }

    override func binding() {
        super.binding()

        bind(in: bag) {
            viewModel.$sections.observeNext { [unowned self] torrents in
                var snapshot = DiffableDataSource<TorrentsListTorrentModel>.Snapshot()
                snapshot.append(torrents)
                dataSource?.apply(snapshot)
            }
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.openTorrentDetails(at: indexPath)
    }
}
