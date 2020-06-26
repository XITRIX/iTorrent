//
//  TorrentListController+DataSource.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 06.04.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

extension TorrentListController {
    func initializeTableView() {
        tableView.allowsMultipleSelectionDuringEditing = true
        
        tableView.register(TableHeaderView.nib, forHeaderFooterViewReuseIdentifier: TableHeaderView.id)
        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = 82
        tableView.rowHeight = 82
        
        torrentListDataSource = TorrentListDataSource(self, tableView: tableView) { (tableView, indexPath, model) -> UITableViewCell in
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TorrentCell
            cell.setModel(model)
            return cell
        }
        
        tableView.dataSource = torrentListDataSource
        tableView.delegate = self
        
        tabBarView.delegate = self
        tabBarView.selectItem(at: IndexPath(item: 0, section: 0))
        
        updateScrollInset()
    }
    
    func updateScrollInset() {
        tableView.scrollIndicatorInsets.top = UserPreferences.sortingSections ? 28 : 44
    }
}

extension TorrentListController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            updateEditStatus()
        } else {
            if let viewController = storyboard?.instantiateViewController(withIdentifier: "Detail") as? TorrentDetailsController,
                let hash = torrentListDataSource.snapshot?.getItem(from: indexPath)?.hash {
                viewController.managerHash = hash
                
                if !splitViewController!.isCollapsed {
                    let navController = storyboard?.instantiateViewController(withIdentifier: "NavigationController") as! UINavigationController
                    navController.viewControllers.append(viewController)
                    navController.isToolbarHidden = false
                    navController.navigationBar.tintColor = navigationController?.navigationBar.tintColor
                    navController.toolbar.tintColor = navigationController?.navigationBar.tintColor
                    splitViewController?.showDetailViewController(navController, sender: self)
                } else {
                    let back = UIBarButtonItem()
                    back.title = " "
                    navigationItem.backBarButtonItem = back
                    splitViewController?.showDetailViewController(viewController, sender: self)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            updateEditStatus()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if !UserPreferences.sortingSections {
            return 44
        }
        
        let sect = torrentListDataSource.snapshot?.sectionIdentifiers[section] ?? ""
        return torrentListDataSource.snapshot?.sectionIdentifiers.count ?? 0 <= section ||
            (torrentListDataSource.snapshot?.numberOfItems(inSection: sect) ?? 0) == 0 ||
//            viewModel.stateFilter.variable != .null ||
            sect.isEmpty ?
            CGFloat.leastNonzeroMagnitude : 28
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if !UserPreferences.sortingSections {
            return tabBarView
        }
        if let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: TableHeaderView.id) as? TableHeaderView {
            cell.title.text = Localize.get(key: torrentListDataSource.snapshot?.sectionIdentifiers[section])
            return cell
        }
        return nil
    }
    
    @available(iOS 13.0, *)
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let hash = torrentListDataSource.snapshot?.getItem(from: indexPath)?.hash,
            splitViewController?.isCollapsed != false else { return nil }
        
        let configuration = UIContextMenuConfiguration(identifier: nil, previewProvider: {
            if let viewController = self.storyboard?.instantiateViewController(withIdentifier: "Detail") as? TorrentDetailsController {
                viewController.managerHash = hash
                return viewController
            }
            return nil
        }) { _ -> UIMenu? in
            if let torrent = Core.shared.torrents[hash] {
                var canStart, canPause: Bool
                if torrent.state == .hashing ||
                    torrent.state == .metadata {
                    canStart = false
                    canPause = false
                } else {
                    if torrent.isFinished, !torrent.seedMode {
                        canStart = false
                        canPause = false
                    } else if torrent.isPaused {
                        canStart = true
                        canPause = false
                    } else {
                        canStart = false
                        canPause = true
                    }
                }
                
                let run = UIAction(title: Localize.get("Start"), image: UIImage(systemName: "play.fill"), identifier: nil, discoverabilityTitle: nil, attributes: canStart ? [] : .hidden, state: .off) { _ in
                    TorrentSdk.startTorrent(hash: hash)
                }
                let pause = UIAction(title: Localize.get("Pause"), image: UIImage(systemName: "pause.fill"), identifier: nil, discoverabilityTitle: nil, attributes: canPause ? [] : .hidden, state: .off) { _ in
                    TorrentSdk.stopTorrent(hash: hash)
                }
                let delete = UIAction(title: Localize.get("Delete"), image: UIImage(systemName: "trash.fill"), identifier: nil, discoverabilityTitle: nil, attributes: .destructive, state: .off) { _ in
                    Core.shared.removeTorrentsUI(hashes: [hash], sender: tableView.cellForRow(at: indexPath)!, direction: .left) {
                        self.viewModel.update()
                    }
                }
                let actionsMenu = UIMenu(title: "",
                                         options: .displayInline,
                                         children: [run, pause])
                
                return UIMenu(title: torrent.title,
                              children: [actionsMenu, delete])
            }
            return nil
        }
        return configuration
    }
    
    @available(iOS 13.0, *)
    func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        animator.addCompletion {
            if let preview = animator.previewViewController {
                let back = UIBarButtonItem()
                back.title = " "
                self.navigationItem.backBarButtonItem = back
                self.splitViewController?.showDetailViewController(preview, sender: self)
                if let nav = preview.navigationController as? SANavigationController,
                    nav.viewControllers.last == preview {
                    nav.locker = false
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        return tableView.isEditing
    }
    
    func tableView(_ tableView: UITableView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        setEditing(true, animated: true)
    }
}

extension TorrentListController: TabBarViewDelegate {
    func filterSelected(_ state: TorrentState) {
        viewModel.stateFilter.variable = state
        viewModel.update()
    }
}
