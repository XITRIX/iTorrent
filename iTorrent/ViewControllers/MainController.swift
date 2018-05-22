//
//  ViewController.swift
//  iTorrent
//
//  Created by  XITRIX on 12.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import UIKit

class MainController: UIViewController, UITableViewDataSource, UITableViewDelegate, ManagersUpdatedDelegate, ManagerStateChangedDelegade {
    @IBOutlet weak var tableView: UITableView!
    
    var managers : [[TorrentStatus]] = []
	var headers : [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        tableView.rowHeight = 104
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
		
		navigationController?.toolbar.tintColor = navigationController?.navigationBar.tintColor
		
		if (!(splitViewController?.isCollapsed)!) {
			splitViewController?.showDetailViewController(Utils.createEmptyViewController(), sender: self)
		}
		
		managers.removeAll()
		managers.append(contentsOf: SortingManager.sortTorrentManagers(managers: Manager.torrentStates, headers: &headers))
        tableView.reloadData()
		
        Manager.managersUpdatedDelegates.append(self)
		Manager.managersStateChangedDelegade.append(self)
        managerUpdated()
    
        navigationController?.isToolbarHidden = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        Manager.managersUpdatedDelegates = Manager.managersUpdatedDelegates.filter({$0 !== (self as ManagersUpdatedDelegate)})
		Manager.managersStateChangedDelegade = Manager.managersStateChangedDelegade.filter({$0 !== (self as ManagerStateChangedDelegade)})
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func managerUpdated() {
		//print("background test")
		var changed = false
		var oldManagers = managers
		managers.removeAll()
		managers.append(contentsOf: SortingManager.sortTorrentManagers(managers: Manager.torrentStates, headers: &headers))
		if (oldManagers.count != managers.count) {
			changed = true
		} else {
			for i in 0 ..< managers.count {
				if (oldManagers[i].count != managers[i].count) {
					changed = true
					break
				}
			}
		}
		if (changed) {
			tableView.reloadData()
		} else {
			for cell in tableView.visibleCells {
				let cell = (cell as! TorrentCell)
				if let manager = Manager.getManagerByHash(hash: cell.manager.hash) {
					cell.manager = manager
					cell.update()
				}
			}
		}
    }
	
	func managerStateChanged(manager: TorrentStatus, oldState: String, newState: String) {
		managers.removeAll()
		managers.append(contentsOf: SortingManager.sortTorrentManagers(managers: Manager.torrentStates, headers: &headers))
		tableView.reloadData()
	}
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return headers.count
	}
	
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return headers[section]
	}
	
	func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
		if (!(view.subviews[0] is UIVisualEffectView)) {
			view.tintColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 0.9)
			let blurEffect = UIBlurEffect(style: .light)
			let blurEffectView = UIVisualEffectView(effect: blurEffect)
			//always fill the view
			blurEffectView.frame = view.bounds
			blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			view.addSubview(blurEffectView)
			view.insertSubview(blurEffectView, at: 0)
		}
	}

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return managers[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TorrentCell
        cell.manager = managers[indexPath.section][indexPath.row]
        cell.update()
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let viewController = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "Detail") as! TorrentDetailsController
        viewController.managerHash = managers[indexPath.section][indexPath.row].hash
        
        if (!(splitViewController?.isCollapsed)!) {
//            if (splitViewController?.viewControllers.count)! > 1, let nav = splitViewController?.viewControllers[1] as? UINavigationController {
//                if let fileController = nav.topViewController
//            }
            let navController = UINavigationController(rootViewController: viewController)
            navController.isToolbarHidden = false
            navController.navigationBar.tintColor = navigationController?.navigationBar.tintColor
            navController.toolbar.tintColor = navigationController?.navigationBar.tintColor
            splitViewController?.showDetailViewController(navController, sender: self)
        } else {
            splitViewController?.showDetailViewController(viewController, sender: self)
        }
    }
	
	func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return true
	}
	
	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		if (editingStyle == .delete) {
			let message = managers[indexPath.section][indexPath.row].hasMetadata ? "Are you sure to remove " + managers[indexPath.section][indexPath.row].title + " torrent?" : "Are you sure to remove this magnet torrent?"
			let removeController = UIAlertController(title: nil, message: message, preferredStyle: .actionSheet)
			let removeAll = UIAlertAction(title: "Yes and remove data", style: .destructive) { _ in
				self.removeTorrent(indexPath: indexPath, removeData: true)
			}
			let removeTorrent = UIAlertAction(title: "Yes but keep data", style: .default) { _ in
				self.removeTorrent(indexPath: indexPath)
			}
			let removeMagnet = UIAlertAction(title: "Remove", style: .destructive) { _ in
				self.removeTorrent(indexPath: indexPath, isMagnet: true)
			}
			let cancel = UIAlertAction(title: "Cancel", style: .cancel)
			if (!managers[indexPath.section][indexPath.row].hasMetadata) {
				removeController.addAction(removeMagnet)
			} else {
				removeController.addAction(removeAll)
				removeController.addAction(removeTorrent)
			}
			removeController.addAction(cancel)
			
			if (removeController.popoverPresentationController != nil) {
				removeController.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
				removeController.popoverPresentationController?.sourceRect = (tableView.cellForRow(at: indexPath)?.bounds)!
				removeController.popoverPresentationController?.permittedArrowDirections = .left
			}
			
			present(removeController, animated: true)
		}
	}
	
	func removeTorrent(indexPath: IndexPath, isMagnet: Bool = false, removeData: Bool = false, visualOnly: Bool = false) {
		if (!visualOnly) {
			let manager = self.managers[indexPath.section][indexPath.row]
			remove_torrent(manager.hash, removeData ? 1 : 0)
			
			if (!(splitViewController?.isCollapsed)!) {
				splitViewController?.showDetailViewController(Utils.createEmptyViewController(), sender: self)
			}
			
			if (!isMagnet) {
				Manager.removeTorrentFile(hash: manager.hash)
				
				if (removeData) {
					if (FileManager.default.fileExists(atPath: Manager.rootFolder + "/" + manager.title)) {
						try! FileManager.default.removeItem(atPath: Manager.rootFolder + "/" + manager.title)
					}
				}
			}
		}
		
		self.managers[indexPath.section].remove(at: indexPath.row)
		if (self.managers[indexPath.section].count > 0) {
			tableView.deleteRows(at: [indexPath], with: .automatic)
		} else {
			self.headers.remove(at: indexPath.section)
			self.managers.remove(at: indexPath.section)
			tableView.deleteSections(NSIndexSet(index: indexPath.section) as IndexSet, with: .automatic)
		}
	}
    
    @IBAction func AddTorrentAction(_ sender: UIBarButtonItem) {
        let addController = UIAlertController(title: "Add from...", message: nil, preferredStyle: .actionSheet)
        
        let addURL = UIAlertAction(title: "URL", style: .default) { _ in
            let addURLController = UIAlertController(title: "Add from URL", message: "Please enter the existing torrent's URL below", preferredStyle: .alert)
            addURLController.addTextField(configurationHandler: { (textField) in
                textField.placeholder = "https://"
            })
            let ok = UIAlertAction(title: "OK", style: .default) { _ in
                let textField = addURLController.textFields![0]
                
                Utils.checkFolderExist(path: Manager.configFolder)
				
				if let url = URL(string: textField.text!) {
					Downloader.load(url: url, to: URL(fileURLWithPath: Manager.configFolder+"/_temp.torrent"), completion: {
						let hash = String(validatingUTF8: get_torrent_file_hash(Manager.configFolder+"/_temp.torrent"))!
						if (Manager.torrentStates.contains(where: {$0.hash == hash})) {
							let controller = UIAlertController(title: "This torrent already exists", message: "Torrent with hash: \"" + hash + "\" already exists in download queue", preferredStyle: .alert)
							let close = UIAlertAction(title: "Close", style: .cancel)
							controller.addAction(close)
							UIApplication.shared.keyWindow?.rootViewController?.present(controller, animated: true)
							return
						}
						let controller = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "AddTorrent")
						((controller as! UINavigationController).topViewController as! AddTorrentController).path = Manager.configFolder+"/_temp.torrent"
						self.present(controller, animated: true)
					}, errorAction: {
						let alertController = UIAlertController(title: "An error occurred", message: "Please, open this link in Safari, and send .torrent file from there", preferredStyle: .alert)
						let close = UIAlertAction(title: "Close", style: .cancel)
						alertController.addAction(close)
						self.present(alertController, animated: true)
					})
				} else {
					let alertController = UIAlertController(title: "Error", message: "Wrong link, check it and try again!", preferredStyle: .alert)
					let close = UIAlertAction(title: "Close", style: .cancel)
					alertController.addAction(close)
					self.present(alertController, animated: true)
				}
            }
            let cancel = UIAlertAction(title: "Cancel", style: .cancel)
            
            addURLController.addAction(ok)
            addURLController.addAction(cancel)
            
            self.present(addURLController, animated: true)
        }
        let addMagnet = UIAlertAction(title: "Magnet", style: .default) { _ in
            let addMagnetController = UIAlertController(title: "Add from magnet", message: "Please enter the magnet link below", preferredStyle: .alert)
            addMagnetController.addTextField(configurationHandler: { (textField) in
                textField.placeholder = "magnet:"
            })
            let ok = UIAlertAction(title: "OK", style: .default) { _ in
                let textField = addMagnetController.textFields![0]
                
                Utils.checkFolderExist(path: Manager.configFolder)
				let hash = String(validatingUTF8: get_magnet_hash(textField.text!))
				if (Manager.torrentStates.contains(where: {$0.hash == hash})) {
					let alert = UIAlertController(title: "This torrent already exists", message: "Torrent with hash: \"" + hash! + "\" already exists in download queue", preferredStyle: .alert)
					let close = UIAlertAction(title: "Close", style: .cancel)
					alert.addAction(close)
					self.present(alert, animated: true)
				}
                
                Manager.addMagnet(textField.text!)
            }
            let cancel = UIAlertAction(title: "Cancel", style: .cancel)
            
            addMagnetController.addAction(ok)
            addMagnetController.addAction(cancel)
            
            self.present(addMagnetController, animated: true)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        
        addController.addAction(addMagnet)
        addController.addAction(addURL)
        addController.addAction(cancel)
		
		if (addController.popoverPresentationController != nil) {
			addController.popoverPresentationController?.barButtonItem = sender
			addController.popoverPresentationController?.permittedArrowDirections = .down
		}
        
        present(addController, animated: true)
    }
    @IBAction func sortAction(_ sender: UIBarButtonItem) {
		let sortingController = SortingManager.createSortingController(buttonItem: sender, applyChanges: {
			self.managers.removeAll()
			self.managers.append(contentsOf: SortingManager.sortTorrentManagers(managers: Manager.torrentStates, headers: &self.headers))
			self.tableView.reloadData();
		})
		present(sortingController, animated: true)
    }
    
}

