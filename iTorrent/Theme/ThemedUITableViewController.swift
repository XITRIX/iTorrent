//
//  ThemedUITableViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 24/06/2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class ThemedUITableViewController : UITableViewController, Themed {
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(themeUpdate), name: Themes.updateNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        themeUpdate()
    }
    
    @objc func themeUpdate() {
        let theme = Themes.current();
        
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = UIUserInterfaceStyle(rawValue: theme.overrideUserInterfaceStyle!)!
        }
        
		setNeedsStatusBarAppearanceUpdate()
		tableView.backgroundColor = theme.backgroundSecondary
		
		tableView.reloadData()
	}
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let theme = Themes.current()
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.textColor = theme.secondaryText
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        let theme = Themes.current()
        if let footer = view as? UITableViewHeaderFooterView {
            footer.textLabel?.textColor = theme.secondaryText
        }
    }
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		return Themes.current().statusBarStyle
	}
	
}
