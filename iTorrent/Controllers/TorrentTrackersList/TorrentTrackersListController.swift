//
//  TorrentTrackersListController.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 02.05.2022.
//

import MVVMFoundation
import SwiftUI
import UIKit

class TorrentTrackersListController: MvvmTableViewController<TorrentTrackersListViewModel> {
    var dataSource: DiffableDataSource<TorrentTrackerModel>!

    let editItem = UIBarButtonItem(title: "Edit", style: .plain, target: nil, action: nil)
    let addItem = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
    let removeItem = UIBarButtonItem(barButtonSystemItem: .trash, target: nil, action: nil)
    let spaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

    override func setupView() {
        super.setupView()

        dataSource = DiffableDataSource<TorrentTrackerModel>(tableView: tableView, cellProvider: { tableView, indexPath, itemIdentifier in
            let cell = tableView.dequeue(for: indexPath) as TorrentTrackerCell
            cell.setup(with: itemIdentifier)
            return cell
        })

        tableView.register(cell: TorrentTrackerCell.self)
        tableView.dataSource = dataSource

        navigationItem.setRightBarButton(editItem, animated: false)
    }

    override func binding() {
        super.binding()

        bind(in: bag) {
            viewModel.$sections.observeNext { [unowned self] sections in
                var snapshot = DiffableDataSource<TorrentTrackerModel>.Snapshot()
                snapshot.append(sections)
                dataSource.apply(snapshot)
            }
            editItem.bindTap(toggleEditState)
            addItem.bindTap(addTrackerAction)
            removeItem.bindTap(removeSelectedTrackersAction)
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        updateSelection()
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        updateSelection()
    }
}

private extension TorrentTrackersListController {
    func toggleEditState() {
        setEditing(!isEditing, animated: true)

        editItem.title = isEditing ? "Done" : "Edit"
        editItem.style = isEditing ? .done : .plain

        if isEditing {
            setToolbarItems([spaceItem, addItem, spaceItem, removeItem, spaceItem], animated: true)
        } else {
            setToolbarItems([], animated: true)
        }
        navigationController?.setToolbarHidden(toolbarHidden, animated: true)
        updateSelection()
    }

    func updateSelection() {
        guard isEditing else { return }
        removeItem.isEnabled = !tableView.indexPathsForSelectedRows.isNilOrEmpty
    }

    func addTrackerAction() {
        let vc = UIAlertController(title: "Add Tracker", message: "Enter the full tracker URL", preferredStyle: .alert)
        vc.addTextField { textField in
            textField.placeholder = "Enter tracker URL"
        }
        vc.addAction(UIAlertAction(title: "Close", style: .cancel))
        vc.addAction(UIAlertAction(title: "Add", style: .default, handler: { [unowned self, unowned vc] _ in
            guard let textField = vc.textFields?.first,
                  let url = textField.text
            else { return }

            viewModel.addTracker(url: url)
        }))
        present(vc, animated: true)
    }

    func removeSelectedTrackersAction() {
        let vc = UIAlertController(title: "Are you shure to remove selected trackers", message: nil, preferredStyle: .actionSheet)
        vc.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        vc.addAction(UIAlertAction(title: "Remove", style: .destructive, handler: { [unowned self] _ in
            guard let selected = tableView.indexPathsForSelectedRows
            else { return }

            viewModel.removeTrackers(at: selected.map { $0.row })
            tableView.indexPathsForSelectedRows?.forEach { tableView.deselectRow(at: $0, animated: true) }
        }))
        present(vc, animated: true)
    }
}
