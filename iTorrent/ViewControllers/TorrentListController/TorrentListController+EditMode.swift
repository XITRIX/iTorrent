//
//  TorrentListController+EditMode.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 06.04.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

#if TRANSMISSION
import ITorrentTransmissionFramework
#else
import ITorrentFramework
#endif

import UIKit

extension TorrentListController {
    func initializeEditMode() {
        initialBarButtonItems.append(contentsOf: navigationItem.rightBarButtonItems!)
        initialBarButtonItems.append(contentsOf: toolbarItems!)

        editmodeBarButtonItems.append(UIBarButtonItem(title: NSLocalizedString("Select All", comment: ""), style: .plain, target: self, action: #selector(selectAllItem(_:))))
        let bottomEditItems: [UIBarButtonItem] = {
            let play = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(startSelectedOfTorrents(_:)))
            let pause = UIBarButtonItem(barButtonSystemItem: .pause, target: self, action: #selector(pauseSelectedOfTorrents(_:)))
            let refresh = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(rehashSelectedTorrents(_:)))
            let trash = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(removeSelectedTorrents(_:)))
            let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
            return [play, space, pause, space, refresh, space, space, space, space, trash]
        }()
        editmodeBarButtonItems.append(contentsOf: bottomEditItems)
    }

    func triggerEditMode() {
        let edit = !tableView.isEditing
        tableView.setEditing(edit, animated: true)
        navigationItem.leftBarButtonItem!.style = edit ? .done : .plain
        navigationItem.leftBarButtonItem!.title = edit ? Localize.get("Done") : Localize.get("Edit")

        if edit {
            navigationItem.setRightBarButtonItems([editmodeBarButtonItems[0]], animated: true)
            setToolbarItems(Array(editmodeBarButtonItems.dropFirst(1)), animated: true)
            updateEditStatus() 
        } else {
            navigationItem.setRightBarButtonItems([initialBarButtonItems[0], initialBarButtonItems[1]], animated: true)
            setToolbarItems(Array(initialBarButtonItems.dropFirst(2)), animated: true)
        }
    }
    
    func updateEditStatus() {
        let count = tableView.indexPathsForSelectedRows?.count ?? 0
        let anySelected = count > 0
        if anySelected {
            navigationItem.rightBarButtonItem?.title = "\(Localize.get("Deselect")) (\(count))"
        } else {
            navigationItem.rightBarButtonItem?.title = Localize.get("Select All")
        }
        toolbarItems?.forEach({$0.isEnabled = anySelected})
    }

    @objc func startSelectedOfTorrents(_ sender: UIBarButtonItem) {
        tableView.indexPathsForSelectedRows?.forEach {
            if let hash = torrentListDataSource.snapshot?.getItem(from: $0)?.hash {
                TorrentSdk.startTorrent(hash: hash)
            }
        }
    }

    @objc func pauseSelectedOfTorrents(_ sender: UIBarButtonItem) {
        tableView.indexPathsForSelectedRows?.forEach {
            if let hash = torrentListDataSource.snapshot?.getItem(from: $0)?.hash {
                TorrentSdk.stopTorrent(hash: hash)
            }
        }
    }

    @objc func rehashSelectedTorrents(_ sender: UIBarButtonItem) {
        if let torrents = tableView.indexPathsForSelectedRows?.compactMap({ torrentListDataSource.snapshot?.getItem(from: $0) }) {
            let message = torrents.map { $0.title }.joined(separator: "\n")

            let controller = ThemedUIAlertController(title: Localize.get("This action will recheck the state of all downloaded files for torrents:"),
                                                     message: message,
                                                     preferredStyle: .actionSheet)
            let hash = UIAlertAction(title: NSLocalizedString("Rehash", comment: ""), style: .destructive) { _ in
                for torrent in torrents {
                    TorrentSdk.rehashTorrent(hash: torrent.hash)
                }
            }
            let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)
            controller.addAction(hash)
            controller.addAction(cancel)

            if controller.popoverPresentationController != nil {
                controller.popoverPresentationController?.barButtonItem = sender
                controller.popoverPresentationController?.permittedArrowDirections = .down
            }

            present(controller, animated: true)
        }
    }

    @objc func removeSelectedTorrents(_ sender: UIBarButtonItem) {
        if let torrents = tableView.indexPathsForSelectedRows?.compactMap({ torrentListDataSource.snapshot?.getItem(from: $0) }) {
            Core.shared.removeTorrentsUI(hashes: torrents.map { $0.hash }, sender: sender, direction: .down) {
                self.tableView.indexPathsForSelectedRows?.forEach({self.tableView.deselectRow(at: $0, animated: true)})
                self.viewModel.update()
                self.updateEditStatus()
            }
        }
    }

    @objc func selectAllItem(_ sender: UIBarButtonItem) {
        let allSelected = tableView.indexPathsForSelectedRows?.count ?? 0 > 0

        if !allSelected {
            for section in 0..<tableView.numberOfSections {
                for row in 0..<tableView.numberOfRows(inSection: section) {
                    tableView.selectRow(at: IndexPath(row: row, section: section), animated: true, scrollPosition: .none)
                }
            }
            if let count = tableView.indexPathsForSelectedRows?.count {
                sender.title = "\(NSLocalizedString("Deselect", comment: "")) (\(count))"
                toolbarItems?.forEach { $0.isEnabled = true }
            }
        } else {
            tableView.indexPathsForSelectedRows?.forEach { tableView.deselectRow(at: $0, animated: true) }
            toolbarItems?.forEach { $0.isEnabled = false }
            sender.title = NSLocalizedString("Select All", comment: "")
        }
    }
} 
