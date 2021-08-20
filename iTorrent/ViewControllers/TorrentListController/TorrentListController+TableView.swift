//
//  TorrentListController+DataSource.swift
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
    func initializeTableView() {
        tableView.allowsMultipleSelectionDuringEditing = true
        
        tableView.register(TabBarView.nib, forHeaderFooterViewReuseIdentifier: TabBarView.id)
        tableView.register(TableHeaderView.nib, forHeaderFooterViewReuseIdentifier: TableHeaderView.id)
        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = 82
        tableView.rowHeight = UITableView.automaticDimension
        
        torrentListDataSource = TorrentListDataSource(self, tableView: tableView) { (tableView, indexPath, model) -> UITableViewCell in
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TorrentCell
            cell.setModel(model)
            return cell
        }
        
        tableView.dataSource = torrentListDataSource
        tableView.delegate = self
        
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
            let viewController = TorrentDetailsController()
            if let hash = torrentListDataSource.snapshot?.getItem(from: indexPath)?.hash {
                viewController.managerHash = hash
                
                if #available(iOS 11, *) {} else {
                    let back = UIBarButtonItem()
                    back.title = " "
                    navigationItem.backBarButtonItem = back
                }
                
                if let splitViewController = splitViewController {
                    if !splitViewController.isCollapsed {
                        let navController = storyboard?.instantiateViewController(withIdentifier: "NavigationController") as! UINavigationController
                        navController.viewControllers.append(viewController)
                        navController.isToolbarHidden = false
                        navController.navigationBar.tintColor = navigationController?.navigationBar.tintColor
                        navController.toolbar.tintColor = navigationController?.navigationBar.tintColor
                        splitViewController.showDetailViewController(navController, sender: self)
                    } else {
                        splitViewController.showDetailViewController(viewController, sender: self)
                    }
                } else {
                    show(viewController, sender: self)
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
            sect.isEmpty ?
            CGFloat.leastNonzeroMagnitude : 28
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if !UserPreferences.sortingSections,
            let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: TabBarView.id) as? TabBarView {
            cell.setModel(self, selected: viewModel.stateFilter.value)
            return cell
        }
        if let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: TableHeaderView.id) as? TableHeaderView {
            cell.title.text = Localize.get(key: torrentListDataSource.snapshot?.sectionIdentifiers[section])
            return cell
        }
        return nil
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if #available(iOS 15.0, *) {
            let safe = tableView.adjustedContentInset.top
            let offset = scrollView.contentOffset.y
            let alpha = min(max(0, offset + safe - 22), 12) / 12
//            print("offset: \(Int(offset)) / safe: \(Int(safe))")
            
            if !UserPreferences.sortingSections,
                let header = tableView.headerView(forSection: 0) as? TabBarView {
                header.backgroundFxView.alpha = alpha
            } else {
                updateHeadersBackground()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if #available(iOS 15.0, *) {
            updateHeadersBackground()
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplayingHeaderView view: UIView, forSection section: Int) {
        if #available(iOS 15.0, *) {
            updateHeadersBackground()
        }
    }
    
    @available(iOS 15.0, *)
    func updateHeadersBackground() {
        var first = true
        let offset = tableView.contentOffset.y
        let safe = tableView.adjustedContentInset.top
        let alpha = min(max(0, offset + safe - 22), 12) / 12
        for i in 0 ..< tableView.numberOfSections {
            guard let header = tableView.headerView(forSection: i) as? TableHeaderView
            else { continue }
            
            print("#\(i): \(Int(header.frame.origin.y)) / \(Int(offset + safe))")
            header.background.alpha = first ? alpha : 0
            first = false
        }
    }
    
    @available(iOS 13.0, *)
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let hash = torrentListDataSource.snapshot?.getItem(from: indexPath)?.hash,
            splitViewController?.isCollapsed != false else { return nil }
        
        let configuration = UIContextMenuConfiguration(identifier: nil, previewProvider: {
            let viewController = TorrentDetailsController()
            viewController.managerHash = hash
            return viewController
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
                self.splitViewController?.showDetailViewController(preview, sender: self)
                if let nav = preview.navigationController as? SANavigationController,
                    nav.viewControllers.last == preview {
                    nav.locker = false
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        tableView.isEditing
    }
    
    func tableView(_ tableView: UITableView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        setEditing(true, animated: true)
    }
}

extension TorrentListController: TabBarViewDelegate {
    func filterSelected(_ state: TorrentState) {
        viewModel.stateFilter.value = state
        viewModel.update()
    }
}
