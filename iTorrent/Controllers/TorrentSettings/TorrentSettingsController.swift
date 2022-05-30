//
//  TorrentSettingsController.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 14.05.2022.
//

import UIKit
import MVVMFoundation

class TorrentSettingsController: BaseTableViewController<TorrentSettingsViewModel> {
    var dataSource: DiffableDataSource<TableCellRepresentable>!

    override func setupView() {
        super.setupView()

        navigationItem.largeTitleDisplayMode = .never

        viewModel.sections.flatMap { $0.items }.forEach { $0.registerCell(in: tableView) }
        dataSource = DiffableDataSource<TableCellRepresentable>.init(tableView: tableView, cellProvider: { tableView, indexPath, itemIdentifier in
            itemIdentifier.resolveCell(in: tableView, for: indexPath)
        })
        tableView.dataSource = dataSource
    }

    override func binding() {
        super.binding()

        bind(in: bag) {
            viewModel.$sections.observeNext { [unowned self] values in
                var snapshot = DiffableDataSource<TableCellRepresentable>.Snapshot()
                snapshot.append(values)
                dataSource.apply(snapshot)
            }

            viewModel.deselectCell.observeNext { [unowned self] _ in
                guard let indexPath = tableView.indexPathForSelectedRow
                else { return }

                tableView.deselectRow(at: indexPath, animated: true)
            }

            tableView.reactive.selectedRowIndexPath.observeNext { [unowned self] indexPath in
                viewModel.sections[indexPath.section].items[indexPath.row].action.send()
            }
        }
    }
}
