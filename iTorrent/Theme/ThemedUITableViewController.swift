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
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(themeUpdate), name: Themes.updateNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        themeUpdate()
    }
    
    @objc func themeUpdate() {
		let theme = UserDefaults.standard.integer(forKey: UserDefaultsKeys.themeNum)
		navigationController?.navigationBar.barStyle = Themes.shared.theme[theme].barStyle
		navigationController?.toolbar.barStyle = Themes.shared.theme[theme].barStyle
		setNeedsStatusBarAppearanceUpdate()
		UIApplication.shared.setStatusBarStyle(Themes.shared.theme[theme].statusBarStyle, animated: true)
		//preferredStatusBarStyle = UIStatusBarStyle.lightContent
		//			UIApplication.shared.statusBarStyle = .lightContent
		tableView.backgroundColor = Themes.shared.theme[theme].backgroundSecondary
		
		tableView.reloadData()
	}
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let theme = UserDefaults.standard.integer(forKey: UserDefaultsKeys.themeNum)
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.textColor = Themes.shared.theme[theme].secondaryText
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        let theme = UserDefaults.standard.integer(forKey: UserDefaultsKeys.themeNum)
        if let footer = view as? UITableViewHeaderFooterView {
            footer.textLabel?.textColor = Themes.shared.theme[theme].secondaryText
        }
    }
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		let theme = UserDefaults.standard.integer(forKey: UserDefaultsKeys.themeNum)
		return Themes.shared.theme[theme].statusBarStyle
	}
	
}
