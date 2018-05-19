//
//  SettingsController.swift
//  iTorrent
//
//  Created by  XITRIX on 15.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class SettingsController: UITableViewController {
    
	@IBOutlet weak var backgroundSwitch: UISwitch!
	@IBOutlet weak var backgroundSeedSwitch: UISwitch!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		backgroundSwitch.setOn(UserDefaults.standard.bool(forKey: UserDefaultsKeys.backgroundKey), animated: false)
		backgroundSeedSwitch.setOn(UserDefaults.standard.bool(forKey: UserDefaultsKeys.backgroundSeedKey), animated: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isToolbarHidden = true
    }
	
	@IBAction func backgroundAction(_ sender: UISwitch) {
		UserDefaults.standard.set(sender.isOn, forKey: UserDefaultsKeys.backgroundKey)
	}
	
	@IBAction func backgroundSeedingAction(_ sender: UISwitch) {
		UserDefaults.standard.set(sender.isOn, forKey: UserDefaultsKeys.backgroundSeedKey)
	}
	
	@IBAction func githubAction(_ sender: UIButton) {
		UIApplication.shared.openURL(URL(string: "https://github.com/XITRIX/iTorrent")!)
	}
}
