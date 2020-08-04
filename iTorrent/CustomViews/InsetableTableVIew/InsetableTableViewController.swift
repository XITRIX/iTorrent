//
//  InsetableTableViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 02.08.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

class InsetableTableViewController: SATableViewController {
    var useInsertStyle: Bool? {
        nil
    }
    
    private var useInsertStyleValue: Bool {
        useInsertStyle ?? false
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if useInsertStyle != nil,
            previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass {
            tableView.reloadData()
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let res = super.tableView(tableView, titleForHeaderInSection: section) {
            return "\(useInsertStyleValue ? "      " : "")\(res)"
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let res = super.tableView(tableView, cellForRowAt: indexPath) as! ThemedUITableViewCell
        res.insetStyle = useInsertStyleValue
        if useInsertStyleValue {
            res.setInsetParams(tableView: tableView, indexPath: indexPath)
        }
        return res
    }
}
