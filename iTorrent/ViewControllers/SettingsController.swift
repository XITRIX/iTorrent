//
//  SettingsController.swift
//  iTorrent
//
//  Created by  XITRIX on 15.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

import MaterialComponents.MaterialSnackbar

class SettingsController: UITableViewController {
    
	@IBOutlet weak var backgroundSwitch: UISwitch!
	@IBOutlet weak var backgroundSeedSwitch: UISwitch!
	@IBOutlet weak var updateLabel: UILabel!
	@IBOutlet weak var updateLoading: UIActivityIndicatorView!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		backgroundSwitch.setOn(UserDefaults.standard.bool(forKey: UserDefaultsKeys.backgroundKey), animated: false)
		backgroundSeedSwitch.setOn(UserDefaults.standard.bool(forKey: UserDefaultsKeys.backgroundSeedKey), animated: false)
		
		checkUpdates()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isToolbarHidden = true
    }
	
	override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		switch section {
		case 0:
			return "Enable downloading in background through multimedia functions"
		case 1:
			let version = try! String(contentsOf: Bundle.main.url(forResource: "Version", withExtension: "ver")!)
			return "Current app version: " + version
		default:
			return nil
		}
	}
	
	func checkUpdates() {
		updateLabel.isHidden = true
		updateLoading.isHidden = false
		updateLoading.startAnimating()
		
		DispatchQueue.global(qos: .background).async {
			if let url = URL(string: "https://raw.githubusercontent.com/XITRIX/iTorrent/master/iTorrent/Version.ver") {
				do {
					let remoteVersion = try String(contentsOf: url)
					
					let localurl = Bundle.main.url(forResource: "Version", withExtension: "ver")
					let localVersion = try String(contentsOf: localurl!)
					
					let res = remoteVersion > localVersion
					DispatchQueue.main.async {
						if (res) {
							self.updateLabel.text = "New version " + remoteVersion + " available"
							self.updateLabel.textColor = UIColor.red
						} else {
							self.updateLabel.text = "Latest version installed"
						}
						self.updateLabel.isHidden = false
						self.updateLoading.isHidden = true
						self.updateLoading.stopAnimating()
					}
				} catch {
					DispatchQueue.main.async {
						self.updateLabel.text = "Update check failed"
						self.updateLabel.isHidden = false
						self.updateLoading.isHidden = true
						self.updateLoading.stopAnimating()
					}
				}
			}
		}
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
	
	@IBAction func donateAction(_ sender: UIButton) {
		UIPasteboard.general.string = "4890494471688218"
		let message = MDCSnackbarMessage()
		message.text = "Copied to pasteboard"
		MDCSnackbarManager.show(message)
	}
}
