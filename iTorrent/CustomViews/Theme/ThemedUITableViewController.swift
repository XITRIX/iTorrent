//
//  ThemedUITableViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 24/06/2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import UIKit

class ThemedUITableViewController: InsetableTableViewController, Themed {
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(themeUpdate), name: Themes.updateNotification, object: nil)
        themeUpdate()
    }

    @objc func themeUpdate() {
        let theme = Themes.current

        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = theme.currentInterfaceStyle
        }

        setNeedsStatusBarAppearanceUpdate()
        tableView.tintColor = theme.tintColor
        tableView.backgroundColor = theme.backgroundSecondary
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? ThemedUITableViewCell {
            cell.setTableView(tableView)
        }
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let theme = Themes.current
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.textColor = theme.secondaryText
        }
    }

    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        let theme = Themes.current
        if let footer = view as? UITableViewHeaderFooterView {
            footer.textLabel?.textColor = theme.secondaryText
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        Themes.current.statusBarStyle
    }
}
