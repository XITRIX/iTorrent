//
//  TorrentFilesController.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 21.04.2022.
//

import MVVMFoundation
import UIKit

class TorrentFilesController: MvvmTableViewController<TorrentFilesViewModel> {
    var dataSource: DiffableDataSource<FileEntityProtocol>?

    override func setupView() {
        super.setupView()

        dataSource = DiffableDataSource<FileEntityProtocol>(tableView: tableView, cellProvider: { [unowned self] tableView, indexPath, itemIdentifier in
            switch itemIdentifier {
            case let file as FileEntity:
                let cell = tableView.dequeue(for: indexPath) as TorrentFileCell
                cell.setup(with: file)
                cell.bind(in: cell.reuseBag) {
                    cell.valueChanged.observeNext { priority in viewModel.setTorrentFilePriority(priority, at: file.id)}
                }
                return cell
            case let directory as DirectoryEntity:
                let cell = tableView.dequeue(for: indexPath) as TorrentDirectoryCell
                cell.setup(with: directory)
                return cell
            default: return UITableViewCell()
            }
        })

        tableView.register(cell: TorrentFileCell.self)
        tableView.register(cell: TorrentDirectoryCell.self)
    }

    override func binding() {
        super.binding()
        bind(in: bag) {
            viewModel.$sections.observeNext { [unowned self] sections in
                var snapshot = DiffableDataSource<FileEntityProtocol>.Snapshot()
                snapshot.append(sections)
                dataSource?.apply(snapshot)
            }

            tableView.reactive.selectedRowIndexPath.observeNext { [unowned self] indexPath in
                if let cell = tableView.cellForRow(at: indexPath) as? TorrentFileCell {
                    return cell.triggerSwitch()
                }
                viewModel.selectItem(at: indexPath)
            }
        }
    }
}
