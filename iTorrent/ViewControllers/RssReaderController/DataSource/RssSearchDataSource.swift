//
//  RssSearchDataSource.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 20.10.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import Bond
import DeepDiff
import ReactiveKit
import UIKit

struct RssSearchItem: Hashable, DiffAware {
    var rss: RssModel
    var item: RssItemModel
}

class RssSearchDataSource: DiffableDataSource<String, RssSearchItem> {
    var tableView: UITableView
    
    init(tableView: UITableView, searchBar: UISearchBar) {
        self.tableView = tableView
        
        tableView.register(RssSearchCell.nib, forCellReuseIdentifier: RssSearchCell.id)
        tableView.estimatedRowHeight = 59

        super.init(tableView: tableView) { (tableView, indexPath, model) -> UITableViewCell in
            let cell = tableView.dequeueReusableCell(withIdentifier: RssSearchCell.id, for: indexPath) as! RssSearchCell
            cell.setModel(model)
            return cell
        }

        combineLatest(searchBar.reactive.text, RssFeedProvider.shared.rssModels) { text, models in
            (searchQuery: text, rssModels: models)
        }.observeNext { combine in
            var items = [RssSearchItem]()
            for rss in combine.rssModels.collection {
                for item in rss.items {
                    if self.searchFilter(item.title, query: combine.searchQuery) {
                        items.append(RssSearchItem(rss: rss, item: item))
                    }
                }
            }
            items.sort(by: { $0.item.date ?? Date.distantPast > $1.item.date ?? Date.distantPast })

            var snapshot = DataSnapshot<String, RssSearchItem>()
            snapshot.appendSections([""])
            snapshot.appendItems(items, toSection: "")
            self.apply(snapshot, animateInitial: false)
        }.dispose(in: bag)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }

    private func searchFilter(_ text: String?, query: String?) -> Bool {
        if let query = query, let text = text {
            let separatedQuery = query.lowercased().split {
                $0 == " " || $0 == ","
            }
            return separatedQuery.allSatisfy { text.lowercased().contains($0) }
        }
        return true
    }
}

extension RssSearchDataSource: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = RssItemController()
        let model = snapshot!.getItem(from: indexPath)!
        vc.setModel(model.item)
        
        setItem(at: indexPath, readed: true)

        tableView.deselectRow(at: indexPath, animated: true)

        let rvc = Utils.rootViewController
        if let splitViewController = rvc as? UISplitViewController {
            if !splitViewController.isCollapsed {
                let navController = Utils.instantiateNavigationController()
                navController.viewControllers.append(vc)
                navController.isToolbarHidden = true
                splitViewController.showDetailViewController(navController, sender: self)
            } else {
                splitViewController.showDetailViewController(vc, sender: self)
            }
        } else {
            rvc.show(vc, sender: self)
        }
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let model = snapshot!.getItem(from: indexPath)!
        let readed = model.item.readed
        let title = readed ? Localize.get("RssChannelController.Unseen") : Localize.get("RssChannelController.Seen")
        let seen = UITableViewRowAction(style: .destructive, title: title) { _, indexPath in
            self.setItem(at: indexPath, readed: !readed)
        }
        return [seen]
    }
    
    func setItem(at indexPath: IndexPath, readed: Bool) {
        var model = snapshot!.getItem(from: indexPath)!
        model.item.new = false
        model.item.readed = readed
        model.rss.items[indexPath.row] = model.item
        (tableView.cellForRow(at: indexPath) as! RssSearchCell).setModel(model)
        RssFeedProvider.shared.rssModels.notifyUpdate()
    }
}
