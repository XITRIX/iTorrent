//
//  TorrentListController+SearchView.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 05.04.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

extension TorrentListController {
    func searchbarUpdateTheme(_ theme: ColorPalett) {
        guard let searchController = searchController else {
            return
        }
        
        searchController.searchBar.keyboardAppearance = theme.keyboardAppearence
        searchController.searchBar.barStyle = theme.barStyle
        searchController.searchBar.tintColor = view.tintColor
        if !searchControllerInsideNavigation {
            searchController.searchBar.barTintColor = theme.backgroundMain
            searchController.searchBar.layer.borderWidth = 1
            searchController.searchBar.layer.borderColor = theme.backgroundMain.cgColor
            UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).backgroundColor = theme.backgroundSecondary

            let back = tableView.backgroundView ?? UIView()
            back.backgroundColor = theme.backgroundMain
            tableView.backgroundView = back
        }
    }

    var searchControllerInsideNavigation: Bool {
        if #available(iOS 11.0, *) {
            return true
        }
        return false
    }

    func initializeSearchView() {
        var resultController: UITableViewController?
        if #available(iOS 13.0, *) {
            resultController = SearchTableViewController()
        }

        searchController = UISearchController(searchResultsController: resultController)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search".localized
        searchController.searchBar.delegate = self
        if #available(iOS 11.0, *),
            searchControllerInsideNavigation
        {
            navigationItem.searchController = searchController
        } else {
            tableView.tableHeaderView = searchController.searchBar
        }

        if #available(iOS 13.0, *) {
            if RssFeedProvider.shared.rssModels.count > 0 {
                searchController.searchBar.scopeButtonTitles = ["Torrents", "RSS"]
            } else {
                searchController.searchBar.scopeButtonTitles = nil
            }

            searchController.showsSearchResultsController = false
        }
    }
}

extension TorrentListController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        if #available(iOS 13.0, *) {
            guard let tableViewController = searchController.searchResultsController as? UITableViewController
            else { return }
            
            searchController.showsSearchResultsController = selectedScope > 0
            
            switch selectedScope {
            case 1:
                if rssSearchDataSource == nil {
                    rssSearchDataSource = RssSearchDataSource(tableView: tableViewController.tableView, searchBar: searchBar)
                }
                tableViewController.tableView.dataSource = rssSearchDataSource
                tableViewController.tableView.delegate = rssSearchDataSource
            default: break
            }
        }
    }
}

extension TorrentListController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.searchFilter.value = searchController.searchBar.text
        viewModel.update()
    }
}

class SearchTableViewController: ThemedUITableViewController {
    override func themeUpdate() {
        super.themeUpdate()
        view.backgroundColor = Themes.current.backgroundMain
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.keyboardDismissMode = .onDrag
    }
}
