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

class TorrentFilesController: BaseTableViewController<TorrentFilesViewModel> {
    var previewDataSource = TorrentFilesControllerPreviewDataSource()
    var dataSource: DiffableDataSource<FileEntityProtocol>?

    let selectAll = UIBarButtonItem(title: "Select All", style: .plain, target: nil, action: nil)
    let deselectAll = UIBarButtonItem(title: "Deselect All", style: .plain, target: nil, action: nil)
    let spaces = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

    let globalItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain, target: nil, action: nil)
    let selectionDoneItem = UIBarButtonItem(title: "Done", style: .done, target: nil, action: nil)
    let shareSelectedItem = UIBarButtonItem(barButtonSystemItem: .action, target: nil, action: nil)
    let prioritySelectedItem = UIBarButtonItem(image: #imageLiteral(resourceName: "Sort"), style: .plain, target: nil, action: nil)

    override func setupView() {
        super.setupView()

        globalItem.menu = createGlobalMenu()
        shareSelectedItem.menu = createShareMenu()
        prioritySelectedItem.menu = createSelectedPriorityMenu()

        setupItems(animated: false)

        dataSource = DiffableDataSource<FileEntityProtocol>(tableView: tableView, cellProvider: { [unowned self] tableView, indexPath, itemIdentifier in
            switch itemIdentifier {
            case let file as FileEntity:
                let cell = tableView.dequeue(for: indexPath) as TorrentFileCell
                cell.setup(with: file)
                cell.menu = createItemMenu(for: indexPath)
                cell.bind(in: cell.reuseBag) {
                    cell.valueChanged.observeNext { priority in viewModel.setPriority(priority, at: indexPath) }
                }
                return cell
            case let directory as DirectoryEntity:
                let cell = tableView.dequeue(for: indexPath) as TorrentDirectoryCell
                cell.setup(with: directory)
                cell.menu = createItemMenu(for: indexPath)
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
            selectionDoneItem.bindTap { [unowned self] in
                setEditing(false, animated: true)
            }
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
                guard !isEditing else { return }

                if let cell = tableView.cellForRow(at: indexPath) as? TorrentFileCell,
                   let file = viewModel.getFile(at: indexPath.row)
                {
                    if file.progress == 1 {
                        previewDataSource.previewURLs = [URL(fileURLWithPath: file.getFullPath(), isDirectory: false)]
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

    override func tableView(_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        true
    }

    override func tableView(_ tableView: UITableView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        setEditing(true, animated: true)
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        setupItems()
    }

    func setupItems(animated: Bool = true) {
        if isEditing {
            navigationItem.setRightBarButton(selectionDoneItem, animated: animated)
            setToolbarItems([prioritySelectedItem, spaces, shareSelectedItem], animated: animated)
        } else {
            navigationItem.setRightBarButton(globalItem, animated: animated)
            setToolbarItems(nil, animated: animated)
        }
    }

    func openSelected() {
        let urls = tableView.indexPathsForSelectedRows?.map { indexPath -> URL in
            let url = viewModel.sections[indexPath.section].items[indexPath.row].getFullPath()
            return URL(fileURLWithPath: url, isDirectory: false)
        }

        guard let urls = urls else { return }

        previewDataSource.previewURLs = urls
        let qlvc = QLPreviewController()
        qlvc.dataSource = previewDataSource
        present(qlvc, animated: true)
    }

    func shareSelected() {
        let urls = tableView.indexPathsForSelectedRows?.map { indexPath -> URL in
            let url = viewModel.sections[indexPath.section].items[indexPath.row].getFullPath()
            return URL(fileURLWithPath: url, isDirectory: false)
        }

        guard let urls = urls else { return }

        let shareController = UIActivityViewController(activityItems: urls, applicationActivities: nil)
        if shareController.popoverPresentationController != nil {
            shareController.popoverPresentationController?.barButtonItem = shareSelectedItem
            shareController.popoverPresentationController?.permittedArrowDirections = .any
        }
        present(shareController, animated: true)
    }
}

// MARK: - UIMenu
extension TorrentFilesController {
    func createShareMenu() -> UIMenu {
        UIMenu(children: [
            UIAction(title: "Share", handler: { [unowned self] _ in
                shareSelected()
            }),
            UIAction(title: "Open", handler: { [unowned self] _ in
                openSelected()
            })
        ])
    }

    func createItemMenu(for indexPath: IndexPath) -> UIMenu? {
        let setPriority: (FileEntry.Priority) -> () = { [unowned self] priority in
            viewModel.setPriority(priority, at: indexPath)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }

        return createPriorityMenu(setPriority)
    }

    func createSelectedPriorityMenu() -> UIMenu {
        let setPriority: (FileEntry.Priority) -> () = { [unowned self] priority in
            let files = tableView.indexPathsForSelectedRows?.map { indexPath -> [FileEntity] in
                let item = viewModel.sections[indexPath.section].items[indexPath.row]
                switch item {
                case let file as FileEntity:
                    return [file]
                case let dir as DirectoryEntity:
                    return dir.getRawFiles()
                default: return []
                }
            }.flatMap { $0 }

            guard let files = files else { return }

            viewModel.setPriorities(priority, for: files)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }

        return createPriorityMenu(title: "Selected items priority", setPriority)
    }

    func createGlobalMenu() -> UIMenu {
        let setPriority: (FileEntry.Priority) -> () = { [unowned self] priority in
            viewModel.setAllTorrentFilesPriority(priority)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }

        let priorityMenu = createPriorityMenu(title: "Priority for all files", setPriority)

        return UIMenu(children: [
            UIAction(title: "Selection mode", image: UIImage(systemName: "checkmark.circle"), handler: { [unowned self] _ in
                setEditing(!isEditing, animated: true)
            }),
            UIAction(title: "Share all", image: UIImage(systemName: "square.and.arrow.up"), handler: { [unowned self] _ in
                let path = NSURL(fileURLWithPath: viewModel.downloadPath, isDirectory: false)
                let shareController = UIActivityViewController(activityItems: [path], applicationActivities: nil)
                if shareController.popoverPresentationController != nil {
                    shareController.popoverPresentationController?.barButtonItem = globalItem
                    shareController.popoverPresentationController?.permittedArrowDirections = .any
                }
                present(shareController, animated: true)
            }),
            UIMenu(options: [.displayInline], children: [priorityMenu])
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

// MARK: - QLPreviewControllerDataSource
class TorrentFilesControllerPreviewDataSource: NSObject, QLPreviewControllerDataSource {
    var previewURLs: [URL] = []

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        previewURLs.count
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        previewURLs[index] as NSURL
    }
}
