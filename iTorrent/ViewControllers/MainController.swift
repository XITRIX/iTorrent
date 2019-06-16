//
//  ViewController.swift
//  iTorrent
//
//  Created by  XITRIX on 12.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import UIKit
import GoogleMobileAds

class MainController: ThemedUIViewController {
    @IBOutlet weak var tableView: ThemedUITableView!
	@IBOutlet weak var adsView: GADBannerView!
    @IBOutlet var tableHeaderView: TableHeaderView!
    
    var managers : [[TorrentStatus]] = []
	var headers : [String] = []
    
    var topRightItemsCopy : [UIBarButtonItem]?
    var bottomItemsCopy : [UIBarButtonItem]?
	lazy var bottomEditItems : [UIBarButtonItem] = {
		let play = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(startSelectedOfTorrents(_:)))
		let pause = UIBarButtonItem(barButtonSystemItem: .pause, target: self, action: #selector(pauseSelectedOfTorrents(_:)))
		let refresh = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(rehashSelectedTorrents(_:)))
		let trash = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(removeSelectedTorrents(_:)))
		let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace , target: self, action: nil)
		return [play, space, pause, space, refresh, space, space, space, space, trash]
	}()
	
	var adsLoaded = false
	
	var tableViewEditMode : Bool = false
    
    override func themeUpdate() {
        super.themeUpdate()
        
        tableView.backgroundColor = Themes.current().backgroundMain
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(TableHeaderView.uiNib(), forHeaderFooterViewReuseIdentifier: "HeaderView")
        
        tableView.allowsMultipleSelectionDuringEditing = true
        
        tableView.tableFooterView = UIView()
        tableView.rowHeight = 104
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.reloadData()
		
		adsView.adUnitID = "ca-app-pub-3833820876743264/1345533898"
		adsView.rootViewController = self
		adsView.load(GADRequest())
		adsView.delegate = self
		
		DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
			if let dialog = UpdatesDialog.summon() {
				self.present(dialog, animated: true)
			}
		}
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
		
		navigationController?.toolbar.tintColor = navigationController?.navigationBar.tintColor
		
		managers.removeAll()
		managers.append(contentsOf: SortingManager.sortTorrentManagers(managers: Manager.torrentStates, headers: &headers))
        tableView.reloadData()
		
		NotificationCenter.default.addObserver(self, selector: #selector(managerUpdated), name: .torrentsUpdated, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(managerStateChanged(notfication:)), name: .torrentsStateChanged, object: nil)
        managerUpdated()
    
        navigationController?.isToolbarHidden = false
		
		if (!UserDefaults.standard.bool(forKey: UserDefaultsKeys.disableAds) && adsLoaded) {
			adsView.isHidden = false
			tableView.contentInset.bottom = adsView.frame.height
			tableView.scrollIndicatorInsets.bottom = adsView.frame.height
		} else {
			adsView.isHidden = true
			tableView.contentInset.bottom = 0
			tableView.scrollIndicatorInsets.bottom = 0
		}
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
		
		NotificationCenter.default.removeObserver(self, name: .torrentsUpdated, object: nil)
		NotificationCenter.default.removeObserver(self, name: .torrentsStateChanged, object: nil)
		
        if (tableView.isEditing) {
            editAction(navigationItem.leftBarButtonItem!)
        }
    }
    
    @objc func managerUpdated() {
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
		
	@objc func managerStateChanged(notfication: NSNotification) {
		managers.removeAll()
		managers.append(contentsOf: SortingManager.sortTorrentManagers(managers: Manager.torrentStates, headers: &headers))
		tableView.reloadData()
	}
	
	func removeTorrent(indexPath: IndexPath, isMagnet: Bool = false, removeData: Bool = false, visualOnly: Bool = false) {
		if (!visualOnly) {
			let manager = managers[indexPath.section][indexPath.row]
			remove_torrent(manager.hash, removeData ? 1 : 0)
			
			if (!(splitViewController?.isCollapsed)!) {
				splitViewController?.showDetailViewController(Utils.createEmptyViewController(), sender: self)
			}
			
			if (!isMagnet) {
				Manager.removeTorrentFile(hash: manager.hash)
				
				if (removeData) {
					do {
						try FileManager.default.removeItem(atPath: Manager.rootFolder + "/" + manager.title)
					} catch {
						print("MainController: removeTorrent()")
						print(error.localizedDescription)
					}
				}
			}
		}
		
		managers[indexPath.section].remove(at: indexPath.row)
		if (managers[indexPath.section].count > 0) {
			tableView.deleteRows(at: [indexPath], with: .automatic)
		} else {
			headers.remove(at: indexPath.section)
			managers.remove(at: indexPath.section)
			tableView.deleteSections(NSIndexSet(index: indexPath.section) as IndexSet, with: .automatic)
		}
	}
    
    @IBAction func AddTorrentAction(_ sender: UIBarButtonItem) {
        let addController = ThemedUIAlertController(title: nil, message: NSLocalizedString("Add from...", comment: ""), preferredStyle: .actionSheet)
        
        let addURL = UIAlertAction(title: "URL", style: .default) { _ in
            let addURLController = ThemedUIAlertController(title: NSLocalizedString("Add from URL", comment: ""), message: NSLocalizedString("Please enter the existing torrent's URL below", comment: ""), preferredStyle: .alert)
            addURLController.addTextField(configurationHandler: { (textField) in
                textField.placeholder = "https://"
				let theme = Themes.current()
				textField.keyboardAppearance = theme.keyboardAppearence
            })
            let ok = UIAlertAction(title: "OK", style: .default) { _ in
                let textField = addURLController.textFields![0]
                
                Utils.checkFolderExist(path: Manager.configFolder)
				
				if let url = URL(string: textField.text!) {
					Downloader.load(url: url, to: URL(fileURLWithPath: Manager.configFolder+"/_temp.torrent"), completion: {
						let hash = String(validatingUTF8: get_torrent_file_hash(Manager.configFolder+"/_temp.torrent"))!
						if (hash == "-1") {
							let controller = ThemedUIAlertController(title: NSLocalizedString("Error has been occured", comment: ""), message: NSLocalizedString("Torrent file is broken or this URL has some sort of DDOS protection, you can try to open this link in Safari", comment: ""), preferredStyle: .alert)
							let safari = UIAlertAction(title: NSLocalizedString("Open in Safari", comment: ""), style: .default) { _ in
								UIApplication.shared.openURL(url)
							}
							let close = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .cancel)
							controller.addAction(safari)
							controller.addAction(close)
							UIApplication.shared.keyWindow?.rootViewController?.present(controller, animated: true)
							return
						}
						if (Manager.torrentStates.contains(where: {$0.hash == hash})) {
							let controller = ThemedUIAlertController(title: NSLocalizedString("This torrent already exists", comment: ""), message: "\(NSLocalizedString("Torrent with hash:", comment: "")) \"" + hash + "\" \(NSLocalizedString("already exists in download queue", comment: ""))", preferredStyle: .alert)
							let close = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .cancel)
							controller.addAction(close)
							UIApplication.shared.keyWindow?.rootViewController?.present(controller, animated: true)
							return
						}
						let controller = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "AddTorrent")
						((controller as! UINavigationController).topViewController as! AddTorrentController).path = Manager.configFolder+"/_temp.torrent"
						self.present(controller, animated: true)
					}, errorAction: {
						let alertController = ThemedUIAlertController(title: NSLocalizedString("Error has been occured", comment: ""), message: NSLocalizedString("Please, open this link in Safari, and send .torrent file from there", comment: ""), preferredStyle: .alert)
						let close = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .cancel)
						alertController.addAction(close)
						self.present(alertController, animated: true)
					})
				} else {
					let alertController = ThemedUIAlertController(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Wrong link, check it and try again!", comment: ""), preferredStyle: .alert)
					let close = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .cancel)
					alertController.addAction(close)
					self.present(alertController, animated: true)
				}
            }
            let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)
            
            addURLController.addAction(ok)
            addURLController.addAction(cancel)
            
            self.present(addURLController, animated: true)
        }
        let addMagnet = UIAlertAction(title: "Magnet", style: .default) { _ in
            let addMagnetController = ThemedUIAlertController(title: NSLocalizedString("Add from magnet", comment: ""), message: NSLocalizedString("Please enter the magnet link below", comment: ""), preferredStyle: .alert)
            addMagnetController.addTextField(configurationHandler: { (textField) in
                textField.placeholder = "magnet:"
				let theme = Themes.current()
				textField.keyboardAppearance = theme.keyboardAppearence
            })
            let ok = UIAlertAction(title: "OK", style: .default) { _ in
                let textField = addMagnetController.textFields![0]
                
                Utils.checkFolderExist(path: Manager.configFolder)
				let hash = String(validatingUTF8: get_magnet_hash(textField.text!))
				if (Manager.torrentStates.contains(where: {$0.hash == hash})) {
					let alert = ThemedUIAlertController(title: NSLocalizedString("This torrent already exists", comment: ""), message: "\(NSLocalizedString("Torrent with hash:", comment: "")) \"" + hash! + "\" \(NSLocalizedString("already exists in download queue", comment: ""))", preferredStyle: .alert)
					let close = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .cancel)
					alert.addAction(close)
					self.present(alert, animated: true)
				}
                
                Manager.addMagnet(textField.text!)
            }
            let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)
            
            addMagnetController.addAction(ok)
            addMagnetController.addAction(cancel)
            
            self.present(addMagnetController, animated: true)
        }
        let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)
        
        addController.addAction(addMagnet)
        addController.addAction(addURL)
        addController.addAction(cancel)
		
		if (addController.popoverPresentationController != nil) {
			addController.popoverPresentationController?.barButtonItem = sender
			addController.popoverPresentationController?.permittedArrowDirections = .down
		}
        
        present(addController, animated: true)
    }
    
    @IBAction func editAction(_ sender: UIBarButtonItem) {
		if (!tableView.isEditing) {
			tableViewEditMode = true
			
		} else {
			tableViewEditMode = false
			
		}
		
        tableView.setEditing(tableViewEditMode, animated: true)
        sender.title = tableViewEditMode ? NSLocalizedString("Done", comment: "") : NSLocalizedString("Edit", comment: "")
		sender.style = tableViewEditMode ? .done : .plain
        
        //NavBarItems
		if (tableViewEditMode) {
			topRightItemsCopy = navigationItem.rightBarButtonItems
			let item = UIBarButtonItem(title: NSLocalizedString("Select All", comment: ""), style: .plain, target: self, action: #selector(selectAllItem(_:)))
			navigationItem.setRightBarButtonItems([item], animated: true)
		} else {
			navigationItem.setRightBarButtonItems(topRightItemsCopy, animated: true)
		}
        
        //ToolBarItems
		if (tableViewEditMode) {
        	bottomItemsCopy = toolbarItems
			setToolbarItems(bottomEditItems, animated: true)
		} else {
			setToolbarItems(bottomItemsCopy, animated: true)
		}
        
        if (tableViewEditMode) {
            navigationItem.rightBarButtonItem?.title = NSLocalizedString("Select All", comment: "")
            for item in toolbarItems! {
                item.isEnabled = false
            }
        }
    }
    
    @IBAction func sortAction(_ sender: UIBarButtonItem) {
		let sortingController = SortingManager.createSortingController(buttonItem: sender, applyChanges: {
			self.managers.removeAll()
			self.managers.append(contentsOf: SortingManager.sortTorrentManagers(managers: Manager.torrentStates, headers: &self.headers))
			self.tableView.reloadData();
		})
		present(sortingController, animated: true)
    }
    
    @objc func selectAllItem(_ sender: UIBarButtonItem) {
        var b = false
        if let count = tableView.indexPathsForSelectedRows?.count {
            b = count > 0
        }
        if (!b) {
            for i in 0 ..< tableView.numberOfSections {
                for j in 0 ..< tableView.numberOfRows(inSection: i) {
                    tableView.selectRow(at: IndexPath(row: j, section: i), animated: true, scrollPosition: .none)
                }
            }
            if let count = tableView.indexPathsForSelectedRows?.count {
                sender.title = "\(NSLocalizedString("Deselect", comment: "")) (\(count))"
                
                for item in toolbarItems! {
                    item.isEnabled = true
                }
            }
        } else {
            for i in 0 ..< tableView.numberOfSections {
                for j in 0 ..< tableView.numberOfRows(inSection: i) {
                    tableView.deselectRow(at: IndexPath(row: j, section: i), animated: true)
                }
            }
            for item in toolbarItems! {
                item.isEnabled = false
            }
            sender.title = NSLocalizedString("Select All", comment: "")
        }
    }
	
	@objc func startSelectedOfTorrents(_ sender: UIBarButtonItem) {
		if let selected = tableView.indexPathsForSelectedRows {
			for indexPath in selected {
				start_torrent(managers[indexPath.section][indexPath.row].hash)
			}
		}
	}
	
	@objc func pauseSelectedOfTorrents(_ sender: UIBarButtonItem) {
		if let selected = tableView.indexPathsForSelectedRows {
			for indexPath in selected {
				stop_torrent(managers[indexPath.section][indexPath.row].hash)
			}
		}
	}
	
	@objc func rehashSelectedTorrents(_ sender: UIBarButtonItem) {
		if let selected = tableView.indexPathsForSelectedRows {
			var selectedHashes : [String] = []
			var message = ""
			for indexPath in selected {
				selectedHashes.append(managers[indexPath.section][indexPath.row].hash)
				message += "\n" + managers[indexPath.section][indexPath.row].title
			}
			
			message = message.trimmingCharacters(in: .whitespacesAndNewlines)
			
			let controller = ThemedUIAlertController(title: NSLocalizedString("This action will recheck the state of all downloaded files for torrents:", comment: ""), message: message, preferredStyle: .actionSheet)
			let hash = UIAlertAction(title: NSLocalizedString("Rehash", comment: ""), style: .destructive) { _ in
				for hash in selectedHashes {
					rehash_torrent(hash)
				}
			}
			let cancel  = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)
			controller.addAction(hash)
			controller.addAction(cancel)
			
			if (controller.popoverPresentationController != nil) {
				controller.popoverPresentationController?.barButtonItem = sender
				controller.popoverPresentationController?.permittedArrowDirections = .down
			}
			
			present(controller, animated: true)
		}
	}
	
	@objc func removeSelectedTorrents(_ sender: UIBarButtonItem) {
		if let selected = tableView.indexPathsForSelectedRows {
			var selectedHashes : [String] = []
			for indexPath in selected {
				selectedHashes.append(managers[indexPath.section][indexPath.row].hash)
			}
			
			var message = ""
			for indexPath in selected {
				message += managers[indexPath.section][indexPath.row].title + "\n"
			}
			message = message.trimmingCharacters(in: .whitespacesAndNewlines)
			
			let removeController = ThemedUIAlertController(title: "\(NSLocalizedString("Are you sure to remove", comment: "")) \(selected.count) \(NSLocalizedString("torrents", comment: ""))?", message: message, preferredStyle: .actionSheet)
			let removeAll = UIAlertAction(title: NSLocalizedString("Yes and remove data", comment: ""), style: .destructive) { _ in
				for hash in selectedHashes {
					var index : IndexPath!
					findHash: for section in 0 ..< self.managers.count {
						for row in 0 ..< self.managers[section].count {
							if (self.managers[section][row].hash == hash) {
								index = IndexPath(row: row, section: section)
								break findHash
							}
						}
					}
					if (index == nil) {
						print("Selected torrent does not exists")
						continue
					}
					
					if (!self.managers[index.section][index.row].hasMetadata) {
						self.removeTorrent(indexPath: index, isMagnet: true)
					} else {
						self.removeTorrent(indexPath: index, removeData: true)
					}
				}
			}
			let removeTorrent = UIAlertAction(title: NSLocalizedString("Yes but keep data", comment: ""), style: .default) { _ in
				for hash in selectedHashes {
					var index : IndexPath!
					findHash: for section in 0 ..< self.managers.count {
						for row in 0 ..< self.managers[section].count {
							if (self.managers[section][row].hash == hash) {
								index = IndexPath(row: row, section: section)
								break findHash
							}
						}
					}
					if (index == nil) {
						print("Selected torrent dows not exists")
						continue
					}
					
					if (!self.managers[index.section][index.row].hasMetadata) {
						self.removeTorrent(indexPath: index, isMagnet: true)
					} else {
						self.removeTorrent(indexPath: index)
					}
				}
			}
			let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)
			
			removeController.addAction(removeAll)
			removeController.addAction(removeTorrent)
			removeController.addAction(cancel)
			
			if (removeController.popoverPresentationController != nil) {
				removeController.popoverPresentationController?.barButtonItem = sender
				removeController.popoverPresentationController?.permittedArrowDirections = .down
			}
			
			present(removeController, animated: true)
			
		}
		
		//let message = managers[indexPath.section][indexPath.row].hasMetadata ? "Are you sure to remove " + managers[indexPath.section][indexPath.row].title + " torrent?" : "Are you sure to remove this magnet torrent?"
		
	}
}

extension MainController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return headers.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (tableView.isEditing) {
            navigationItem.rightBarButtonItem?.title = NSLocalizedString("Select All", comment: "")
        }
        return managers[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TorrentCell
        cell.manager = managers[indexPath.section][indexPath.row]
        cell.update()
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            let selectedHash = managers[indexPath.section][indexPath.row].hash
            let message = managers[indexPath.section][indexPath.row].hasMetadata ? NSLocalizedString("Are you sure to remove", comment: "") + " " + managers[indexPath.section][indexPath.row].title + " \(NSLocalizedString("torrent", comment: ""))?" : NSLocalizedString("Are you sure to remove this magnet torrent?", comment: "")
            let removeController = ThemedUIAlertController(title: nil, message: message, preferredStyle: .actionSheet)
            let removeAll = UIAlertAction(title: NSLocalizedString("Yes and remove data", comment: ""), style: .destructive) { _ in
                findHash: for section in 0 ..< self.managers.count {
                    for row in 0 ..< self.managers[section].count {
                        if (self.managers[section][row].hash == selectedHash) {
                            self.removeTorrent(indexPath: IndexPath(row: row, section: section), removeData: true)
                            break findHash
                        }
                    }
                }
            }
            let removeTorrent = UIAlertAction(title: NSLocalizedString("Yes but keep data", comment: ""), style: .default) { _ in
                findHash: for section in 0 ..< self.managers.count {
                    for row in 0 ..< self.managers[section].count {
                        if (self.managers[section][row].hash == selectedHash) {
                            self.removeTorrent(indexPath: IndexPath(row: row, section: section))
                            break findHash
                        }
                    }
                }
            }
            let removeMagnet = UIAlertAction(title: NSLocalizedString("Remove", comment: ""), style: .destructive) { _ in
                findHash: for section in 0 ..< self.managers.count {
                    for row in 0 ..< self.managers[section].count {
                        if (self.managers[section][row].hash == selectedHash) {
                            self.removeTorrent(indexPath: IndexPath(row: row, section: section), isMagnet: true)
                            break findHash
                        }
                    }
                }
            }
            let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)
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
}

extension MainController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return headers[section].isEmpty ? 0 : 28
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: "HeaderView") as! TableHeaderView
        let theme = Themes.current()

        cell.title.text = NSLocalizedString(headers[section], comment: "")
        cell.background.effect = UIBlurEffect(style: theme.blurEffect)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (tableView.isEditing) {
            var b = true
            if let count = (tableView.indexPathsForSelectedRows?.count) {
                b = count > 0
                navigationItem.rightBarButtonItem?.title = "\(NSLocalizedString("Deselect", comment: "")) (\(count))"
            }
            for item in toolbarItems! {
                item.isEnabled = b
            }
            
        } else {
            let viewController = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "Detail") as! TorrentDetailsController
            viewController.managerHash = managers[indexPath.section][indexPath.row].hash
            
            if (!(splitViewController?.isCollapsed)!) {
                //            if (splitViewController?.viewControllers.count)! > 1, let nav = splitViewController?.viewControllers[1] as? UINavigationController {
                //                if let fileController = nav.topViewController
                //            }
                let navController = ThemedUINavigationController(rootViewController: viewController)
                navController.isToolbarHidden = false
                navController.navigationBar.tintColor = navigationController?.navigationBar.tintColor
                navController.toolbar.tintColor = navigationController?.navigationBar.tintColor
                splitViewController?.showDetailViewController(navController, sender: self)
            } else {
                splitViewController?.showDetailViewController(viewController, sender: self)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if (tableView.isEditing) {
            var b = false
            if let count = (tableView.indexPathsForSelectedRows?.count) {
                b = count > 0
                navigationItem.rightBarButtonItem?.title = "\(NSLocalizedString("Deselect", comment: "")) (\(count))"
            } else {
                navigationItem.rightBarButtonItem?.title = NSLocalizedString("Select All", comment: "")
            }
            for item in toolbarItems! {
                item.isEnabled = b
            }
        }
    }
}

extension MainController: GADBannerViewDelegate {
    func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        adsLoaded = false
        
        bannerView.isHidden = true
        tableView.contentInset.bottom = 0
        tableView.scrollIndicatorInsets.bottom = 0
    }
    
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        // Add banner to view and add constraints as above.
        adsLoaded = true
        if (!UserDefaults.standard.bool(forKey: UserDefaultsKeys.disableAds)) {
            bannerView.isHidden = false
            tableView.contentInset.bottom = bannerView.frame.height
            tableView.scrollIndicatorInsets.bottom = bannerView.frame.height
        }
    }
}

