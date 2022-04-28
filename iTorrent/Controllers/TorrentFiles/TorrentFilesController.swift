//
//  TorrentFilesController.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 21.04.2022.
//

import MVVMFoundation
import QuickLook
import TorrentKit
import UIKit

class TorrentFilesController: MvvmTableViewController<TorrentFilesViewModel> {
    var previewDataSource = TorrentFilesControllerPreviewDataSource()
    var dataSource: DiffableDataSource<FileEntityProtocol>?

    let selectAll = UIBarButtonItem(title: "Select All", style: .plain, target: nil, action: nil)
    let deselectAll = UIBarButtonItem(title: "Deselect All", style: .plain, target: nil, action: nil)
    let spaces = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

    override func setupView() {
        super.setupView()

        toolbarItems = [selectAll, spaces, deselectAll]

        dataSource = DiffableDataSource<FileEntityProtocol>(tableView: tableView, cellProvider: { [unowned self] tableView, indexPath, itemIdentifier in
            switch itemIdentifier {
            case let file as FileEntity:
                let cell = tableView.dequeue(for: indexPath) as TorrentFileCell
                cell.setup(with: file)
                cell.menu = createFileMenu(at: file.index)
                cell.bind(in: cell.reuseBag) {
                    cell.valueChanged.observeNext { priority in viewModel.setTorrentFilePriority(priority, at: file.index) }
                }
                return cell
            case let directory as DirectoryEntity:
                let cell = tableView.dequeue(for: indexPath) as TorrentDirectoryCell
                cell.setup(with: directory)
                cell.menu = createFolderMenu(for: indexPath)
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
            selectAll.bindTap { [unowned self] in
                viewModel.setAllTorrentFilesPriority(.defaultPriority)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            deselectAll.bindTap { [unowned self] in
                viewModel.setAllTorrentFilesPriority(.dontDownload)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            viewModel.$sections.observeNext { [unowned self] sections in
                var snapshot = DiffableDataSource<FileEntityProtocol>.Snapshot()
                snapshot.append(sections)
                dataSource?.apply(snapshot)
            }

            tableView.reactive.selectedRowIndexPath.observeNext { [unowned self] indexPath in
                if let cell = tableView.cellForRow(at: indexPath) as? TorrentFileCell,
                   let file = viewModel.getFile(at: indexPath.row)
                {
                    if file.progress == 1 {
                        previewDataSource.previewURL = URL(fileURLWithPath: file.getFullPath(), isDirectory: false)
                        let qlvc = QLPreviewController()
                        qlvc.dataSource = previewDataSource
                        present(qlvc, animated: true)
                    } else { cell.triggerSwitch() }
                    return
                }
                viewModel.selectItem(at: indexPath)
            }
        }
    }

    func createFileMenu(at fileIndex: Int) -> UIMenu? {
        let setPriority: (FileEntry.Priority) -> () = { [unowned self] priority in
            viewModel.setTorrentFilePriority(priority, at: fileIndex)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }

        return createPriorityMenu(setPriority)
    }

    func createFolderMenu(for indexPath: IndexPath) -> UIMenu? {
        let setPriority: (FileEntry.Priority) -> () = { [unowned self] priority in
            viewModel.setTorrentDictionaryPriority(priority, at: indexPath.row)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }

        return createPriorityMenu(setPriority)
    }

    func createPriorityMenu(_ priorityCallback: @escaping (FileEntry.Priority)->()) -> UIMenu {
        let loadMenu = UIMenu(title: "", options: [.displayInline], children: [
            UIAction(title: "Low priority") { _ in
                priorityCallback(.lowPriority)
            },
            UIAction(title: "Default priority") { _ in
                priorityCallback(.defaultPriority)
            },
            UIAction(title: "High priority") { _ in
                priorityCallback(.topPriority)
            }
        ])

        let notLoadMenu = UIMenu(title: "", options: [.displayInline], children: [
            UIAction(title: "Don't donwnload") { _ in
                priorityCallback(.dontDownload)
            }
        ])

        return UIMenu(title: "Priority", children: [notLoadMenu, loadMenu])
    }
}

class TorrentFilesControllerPreviewDataSource: NSObject, QLPreviewControllerDataSource {
    var previewURL: URL?

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        previewURL == nil ? 0 : 1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        guard let url = previewURL else { fatalError() }
        return url as NSURL
    }
}
