//
//  SettingsController.swift
//  iTorrent
//
//  Created by  XITRIX on 15.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class SettingsController: ThemedUITableViewController {
    
	@IBOutlet weak var darkThemeSwitch: UISwitch!
	@IBOutlet weak var backgroundSwitch: UISwitch!
	@IBOutlet weak var backgroundSeedSwitch: UISwitch!
	@IBOutlet weak var ftpSwitch: UISwitch!
	@IBOutlet weak var ftpBackgroundSwitch: UISwitch!
	@IBOutlet weak var notificationSwitch: UISwitch!
	@IBOutlet weak var badgeSwitch: UISwitch!
	@IBOutlet weak var updateLabel: UILabel!
	@IBOutlet weak var updateLoading: UIActivityIndicatorView!
	
    deinit {
        print("Settings DEINIT")
    }
    
	override func viewDidLoad() {
        super.viewDidLoad()
		
		darkThemeSwitch.setOn(UserDefaults.standard.integer(forKey: UserDefaultsKeys.themeNum) == 1, animated: false)
		
		let back = UserDefaults.standard.bool(forKey: UserDefaultsKeys.backgroundKey)
		backgroundSwitch.setOn(back, animated: false)
		
		backgroundSeedSwitch.isEnabled = back
		backgroundSeedSwitch.setOn(UserDefaults.standard.bool(forKey: UserDefaultsKeys.backgroundSeedKey), animated: false)
		
		let ftp = UserDefaults.standard.bool(forKey: UserDefaultsKeys.ftpKey)
		ftpSwitch.setOn(ftp, animated: false)
		
		ftpBackgroundSwitch.isEnabled = ftp && back
		ftpBackgroundSwitch.setOn(UserDefaults.standard.bool(forKey: UserDefaultsKeys.ftpBackgroundKey), animated: false)
		
		let notif = UserDefaults.standard.bool(forKey: UserDefaultsKeys.notificationsKey)
		notificationSwitch.setOn(notif, animated: false)
		
		badgeSwitch.isEnabled = notif
		badgeSwitch.setOn(UserDefaults.standard.bool(forKey: UserDefaultsKeys.badgeKey), animated: false)
		
		checkUpdates()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isToolbarHidden = true
    }
	
	override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		switch section {
		case 1:
			return "Enable downloading in background through multimedia functions"
		case 2:
			let addr = Utils.getWiFiAddress()
			if let addr = addr {
				let b = UserDefaults.standard.bool(forKey: UserDefaultsKeys.ftpKey)
				return b ? "Connect to: ftp://" + addr + ":21" : ""
			} else {
				return "Connect to WIFI to use FTP"
			}
		case 4:
			let version = try! String(contentsOf: Bundle.main.url(forResource: "Version", withExtension: "ver")!)
			return "Current app version: " + version
		default:
			return nil
		}
	}
	
	func setSwitchHides() {
		backgroundSeedSwitch.isEnabled = backgroundSwitch.isOn
		ftpBackgroundSwitch.isEnabled = ftpSwitch.isOn && backgroundSwitch.isOn
		badgeSwitch.isEnabled = notificationSwitch.isOn
		notificationSwitch.isEnabled = backgroundSwitch.isOn
		badgeSwitch.isEnabled = backgroundSwitch.isOn
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
	
	@IBAction func darkThemeAction(_ sender: UISwitch) {
		UserDefaults.standard.set(sender.isOn ? 1 : 0, forKey: UserDefaultsKeys.themeNum)
		self.updateTheme()
		
		if (!(splitViewController?.isCollapsed)!) {
			if let themed = splitViewController?.viewControllers.last as? Themed {
				themed.updateTheme()
			} else if let nav = splitViewController?.viewControllers.last as? UINavigationController,
				let themed = nav.topViewController as? Themed {
				themed.updateTheme()
			} else {
				print("NO")
			}
		}
	}
	
	@IBAction func backgroundAction(_ sender: UISwitch) {
		UserDefaults.standard.set(sender.isOn, forKey: UserDefaultsKeys.backgroundKey)
		setSwitchHides()
	}
	
	@IBAction func backgroundSeedingAction(_ sender: UISwitch) {
		if (sender.isOn) {
            let controller = ThemedUIAlertController(title: "WARNING", message: "This will let iTorrent run in in the background permanently, in case any torrent is seeding, which can cause significant battery drain. \n\nYou will need to force close the app to stop this!", preferredStyle: .alert)
			let enable = UIAlertAction(title: "Enable", style: .destructive) { _ in
				UserDefaults.standard.set(sender.isOn, forKey: UserDefaultsKeys.backgroundSeedKey)
			}
			let close = UIAlertAction(title: "Cancel", style: .cancel) { _ in
				sender.setOn(false, animated: true)
			}
			controller.addAction(enable)
			controller.addAction(close)
			present(controller, animated: true)
		} else {
			UserDefaults.standard.set(sender.isOn, forKey: UserDefaultsKeys.backgroundSeedKey)
		}
	}
	
	@IBAction func ftpAction(_ sender: UISwitch) {
		UserDefaults.standard.set(sender.isOn, forKey: UserDefaultsKeys.ftpKey)
		sender.isOn ? Manager.startFTP() : Manager.stopFTP()
		setSwitchHides()
		tableView.reloadData()
	}
	
	@IBAction func ftpBackgroundAction(_ sender: UISwitch) {
		if (sender.isOn) {
			let controller = ThemedUIAlertController(title: "WARNING", message: "This will let iTorrent run in the background permanently, which can cause significant battery drain. \n\nYou will need to force close the app to stop this!", preferredStyle: .alert)
			let enable = UIAlertAction(title: "Enable", style: .destructive) { _ in
				UserDefaults.standard.set(sender.isOn, forKey: UserDefaultsKeys.ftpBackgroundKey)
			}
			let close = UIAlertAction(title: "Cancel", style: .cancel) { _ in
				sender.setOn(false, animated: true)
			}
			controller.addAction(enable)
			controller.addAction(close)
			present(controller, animated: true)
		} else {
			UserDefaults.standard.set(sender.isOn, forKey: UserDefaultsKeys.ftpBackgroundKey)
		}
	}
	
	@IBAction func notificationAction(_ sender: UISwitch) {
		UserDefaults.standard.set(sender.isOn, forKey: UserDefaultsKeys.notificationsKey)
		setSwitchHides()
	}
	
	@IBAction func badgeAction(_ sender: UISwitch) {
		UserDefaults.standard.set(sender.isOn, forKey: UserDefaultsKeys.badgeKey)
	}
	
    @IBAction func githubAction(_ sender: UIButton) {
        func open (scheme: String) {
            if let url = URL(string: scheme) {
                if #available(iOS 10, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
                else {
                    UIApplication.shared.openURL(url)
                }
            }
        }
        open(scheme: "https://github.com/XITRIX/iTorrent")
    }
    
    //rewritten to remove Snackbar dependency
    //https://stackoverflow.com/questions/3737911/how-to-display-temporary-popup-message-on-iphone-ipad-ios#7133966
    @IBAction func donateAction(_ sender: UIButton) {
        UIPasteboard.general.string = "5106211026617147" //4890494471688218
        let alert = ThemedUIAlertController(title: "", message: "Copied CC # to clipboard!", preferredStyle: .alert)
        self.present(alert, animated: true, completion: nil)
        // change alert timer to 2 seconds, then dismiss
        let when = DispatchTime.now() + 2
        DispatchQueue.main.asyncAfter(deadline: when){
            alert.dismiss(animated: true, completion: nil)
        }
    }
}
