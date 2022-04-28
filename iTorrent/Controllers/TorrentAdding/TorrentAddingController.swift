//
//  TorrentAddingController.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 25.04.2022.
//

import MVVMFoundation
import TorrentKit
import UIKit

class TorrentAddingController: MvvmTableViewController<TorrentAddingViewModel> {
    let doneItem = UIBarButtonItem(title: "Download", style: .done, target: nil, action: nil)
    let cancelItem = UIBarButtonItem(title: "Cancel", style: .plain, target: nil, action: nil)
    let globalItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), style: .plain, target: nil, action: nil)

    var previewDataSource = TorrentFilesControllerPreviewDataSource()
    var dataSource: DiffableDataSource<FileEntityProtocol>?

    deinit {
        print("Deinit TorrentAddingController!")
    }

    override func setupView() {
        super.setupView()

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.setRightBarButton(doneItem, animated: false)
        globalItem.menu = createGlobalMenu()
        toolbarItems = [globalItem]

        if viewModel.rootDirectory {
            navigationItem.setLeftBarButton(cancelItem, animated: false)
        }

        navigationController?.isModalInPresentation = true

        dataSource = DiffableDataSource<FileEntityProtocol>(tableView: tableView, cellProvider: { [unowned self] tableView, indexPath, itemIdentifier in
            switch itemIdentifier {
            case let file as FileEntity:
                let cell = tableView.dequeue(for: indexPath) as TorrentFileCell
                cell.setup(with: file)
                cell.menu = createFileMenu(for: file.index)
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

private extension TorrentAddingController {
    func createFileMenu(for fileIndex: Int) -> UIMenu? {
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

    func createGlobalMenu() -> UIMenu? {
        let setPriority: (FileEntry.Priority) -> () = { [unowned self] priority in
            viewModel.setAllTorrentFilesPriority(priority)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }

        let priorityMenu = createPriorityMenu(title: "Priority for all files", setPriority)

        return UIMenu(children: [
            UIMenu(options: [.displayInline], children: [priorityMenu]),
            UIAction(title: "Selection mode", handler: { _ in

            })
        ])
    }

    func createPriorityMenu(title: String = "Priority", _ priorityCallback: @escaping (FileEntry.Priority) -> ()) -> UIMenu {
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

        return UIMenu(title: title, children: [notLoadMenu, loadMenu])
    }
}
