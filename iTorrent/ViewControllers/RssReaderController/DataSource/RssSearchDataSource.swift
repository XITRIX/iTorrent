//
//  RssSearchDataSource.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 20.10.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit
import DeepDiff
import Bond
import ReactiveKit

struct RssSearchItem: Hashable, DiffAware {
    var rss: RssModel
    var item: RssItemModel
}

class RssSearchDataSource: DiffableDataSource<String, RssSearchItem> {
    init(tableView: UITableView, searchBar: UISearchBar) {
        tableView.register(RssSearchCell.nib, forCellReuseIdentifier: RssSearchCell.id)
        tableView.estimatedRowHeight = 59
        
        super.init(tableView: tableView) { (tableView, indexPath, model) -> UITableViewCell in
            let cell = tableView.dequeueReusableCell(withIdentifier: RssSearchCell.id, for: indexPath) as! RssSearchCell
            cell.title.text = model.item.title
            cell.descriptionText.text = model.rss.displayTitle
            
            if let datet = model.item.date {
                let now = Date()
                cell.date.isHidden = false
                cell.date.text = now.offset(from: datet)
            } else {
                cell.date.isHidden = true
            }
            
            cell.imageFav.image = UIImage(named: "Rss")
            cell.imageFav.load(url: model.rss.linkImage)
            
            return cell
        }
        
        searchBar.reactive.text.observeNext { text in
            var items = [RssSearchItem]()
            for rss in RssFeedProvider.shared.rssModels.collection {
                for item in rss.items {
                    if self.searchFilter(item.title, query: text) {
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
    
    private func searchFilter(_ text: String?, query: String?) -> Bool {
        if let query = query,
           let text = text {
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
        
        if let index = model.rss.items.firstIndex(of: model.item) {
            model.rss.items[index].readed = true
        }
        
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
}
