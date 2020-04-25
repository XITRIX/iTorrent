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
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = Localize.get("Search")
        if #available(iOS 11.0, *),
            searchControllerInsideNavigation {
            navigationItem.searchController = searchController
        } else {
            tableView.tableHeaderView = searchController.searchBar
        }
    }
    
    func searchFilter(_ model: TorrentModel) -> Bool {
        if let filter = searchFilter {
            let separatedQuery = filter.lowercased().split {
                $0 == " " || $0 == ","
            }
            return separatedQuery.allSatisfy({model.title.lowercased().contains($0)})
        }
        return true
    }
}

extension TorrentListController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        searchFilter = searchController.searchBar.text
        update()
    }
}
