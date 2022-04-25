//
//  TorrentAddingController.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 25.04.2022.
//

import UIKit
import MVVMFoundation

class TorrentAddingController: MvvmTableViewController<TorrentAddingViewModel> {
    let doneItem = UIBarButtonItem(title: "Download", style: .done, target: nil, action: nil)
    let cancelItem = UIBarButtonItem(title: "Cancel", style: .plain, target: nil, action: nil)

    var previewDataSource = TorrentFilesControllerPreviewDataSource()
    var dataSource: DiffableDataSource<FileEntityProtocol>?

    deinit {
        print("Deinit TorrentAddingController!")
    }

    override func setupView() {
        super.setupView()

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.setRightBarButton(doneItem, animated: false)
        navigationItem.setLeftBarButton(cancelItem, animated: false)

        dataSource = DiffableDataSource<FileEntityProtocol>(tableView: tableView, cellProvider: { [unowned self] tableView, indexPath, itemIdentifier in
            switch itemIdentifier {
            case let file as FileEntity:
                let cell = tableView.dequeue(for: indexPath) as TorrentFileCell
                cell.setup(with: file)
                cell.bind(in: cell.reuseBag) {
                    cell.valueChanged.observeNext { priority in viewModel.setTorrentFilePriority(priority, at: file.id) }
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
                    cell.triggerSwitch()
                    return
                }
                viewModel.selectItem(at: indexPath)
            }

            doneItem.bindTap(viewModel.download)
            cancelItem.bindTap(viewModel.dismiss)
        }
    }
}
