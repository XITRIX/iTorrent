//
//  TorrentListDataSource.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 02.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

#if TRANSMISSION
import ITorrentTransmissionFramework
#else
import ITorrentFramework
#endif

import UIKit

class TorrentListDataSource: DiffableDataSource<String, TorrentModel> {
    weak var controller: TorrentListController!

    init(_ torrentListController: TorrentListController, tableView: UITableView, cellProvider: @escaping DiffableDataSource<TorrentState, TorrentModel>.CellProvider) {
        super.init(tableView: tableView, cellProvider: cellProvider)
        self.controller = torrentListController
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard let hash = snapshot?.getItem(from: indexPath)?.hash else { return }
        let hashes = [hash]

        Core.shared.removeTorrentsUI(hashes: hashes, sender: tableView.cellForRow(at: indexPath)!, direction: .left) {
            self.controller.viewModel.update()

            // if detail view opens with deleted hash, close it
            if let splitViewController = self.controller.splitViewController,
                !splitViewController.isCollapsed,
                let nav = splitViewController.viewControllers.last(where: {$0 is UINavigationController}) as? UINavigationController,
                let detailView = nav.viewControllers.first as? TorrentDetailsController {
                if hashes.contains(where: { $0 == detailView.managerHash }) {
                    splitViewController.showDetailViewController(Utils.createEmptyViewController(), sender: self)
                }
            }
        }
    }
}
