//
//  TorrentDetailsController.swift
//  iTorrent
//
//  Created by  XITRIX on 15.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class TorrentDetailsController: ThemedUITableViewController, ManagersUpdatedDelegate {
    @IBOutlet weak var start: UIBarButtonItem!
    @IBOutlet weak var pause: UIBarButtonItem!
    @IBOutlet weak var rehash: UIBarButtonItem!
	@IBOutlet weak var switcher: UISwitch!
	
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var downloadLabel: UILabel!
    @IBOutlet weak var uploadLabel: UILabel!
    @IBOutlet weak var timeRemainsLabel: UILabel!
    @IBOutlet weak var hashLabel: UILabel!
    @IBOutlet weak var creatorLabel: UILabel!
    @IBOutlet weak var createdOnLabel: UILabel!
    @IBOutlet weak var addedOnLabel: UILabel!
    @IBOutlet weak var commentsLabel: UILabel!
    @IBOutlet weak var selectedLabel: UILabel!
    @IBOutlet weak var completedLabel: UILabel!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var downloadedLabel: UILabel!
    @IBOutlet weak var uploadedLabel: UILabel!
    @IBOutlet weak var seedersLabel: UILabel!
    @IBOutlet weak var peersLabel: UILabel!
    
    var managerHash : String!
    
    deinit {
        print("Details DEINIT")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
		if (managerHash == nil) {
			return
		}
		
		let calendar = Calendar.current
		var saves = Manager.managerSaves[managerHash]
		if (saves == nil) {
			Manager.managerSaves[managerHash] = UserManagerSettings()
			saves = Manager.managerSaves[managerHash]
		}
		switcher.setOn((saves?.seedMode)! , animated: false)
		let date = saves?.addedDate ?? Date()
		addedOnLabel.text = String(calendar.component(.day, from: date)) + "/" + String(calendar.component(.month, from: date)) + "/" + String(calendar.component(.year, from: date))
		
		managerUpdated()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
		if (managerHash == nil) {
			return
		}
        
        managerUpdated()
        Manager.managersUpdatedDelegates.append(self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        Manager.managersUpdatedDelegates = Manager.managersUpdatedDelegates.filter({$0 !== (self as ManagersUpdatedDelegate)})
    }
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		if (managerHash == nil) {
			return 0
		}
		return super.numberOfSections(in: tableView)
	}
    
    func managerUpdated() {
        if managerHash != nil,
            let manager = Manager.getManagerByHash(hash: managerHash) {
            let calendar = Calendar.current
            
            title = manager.title
            stateLabel.text = manager.displayState
            downloadLabel.text = Utils.getSizeText(size: Int64(manager.downloadRate)) + "/s"
            uploadLabel.text = Utils.getSizeText(size: Int64(manager.uploadRate)) + "/s"
            timeRemainsLabel.text = manager.displayState == Utils.torrentStates.Downloading.rawValue ? Utils.downloadingTimeRemainText(speedInBytes: Int64(manager.downloadRate), fileSize: manager.totalWanted, downloadedSize: manager.totalWantedDone) : "---"
            hashLabel.text = manager.hash.uppercased()
            creatorLabel.text = manager.creator
            createdOnLabel.text = String(calendar.component(.day, from: manager.creationDate!)) + "/" + String(calendar.component(.month, from: manager.creationDate!)) + "/" + String(calendar.component(.year, from: manager.creationDate!))
            commentsLabel.text = manager.comment
            selectedLabel.text = Utils.getSizeText(size: manager.totalWanted) + " / " + Utils.getSizeText(size: manager.totalSize)
            completedLabel.text = Utils.getSizeText(size: manager.totalWantedDone)
            progressLabel.text = String(format: "%.2f", Double(manager.totalWantedDone) / Double(manager.totalWanted) * 100) + "% / " + String(format: "%.2f", Double(manager.totalDone) / Double(manager.totalSize) * 100) + "%"
            downloadedLabel.text = Utils.getSizeText(size: manager.totalDownload)
            uploadedLabel.text = Utils.getSizeText(size: manager.totalUpload)
            seedersLabel.text = String(manager.numSeeds)
            peersLabel.text = String(manager.numPeers)
            
//            print(manager.isPaused)
//            print(manager.isFinished)
//            print(manager.isSeed)
//            print(manager.seedMode)
//            print("------------")
			
            if (manager.state == Utils.torrentStates.Hashing.rawValue ||
				manager.state == Utils.torrentStates.Metadata.rawValue) {
                start.isEnabled = false
                pause.isEnabled = false
                rehash.isEnabled = false
            } else {
				if (manager.isFinished && !switcher.isOn) {
					start.isEnabled = false
					pause.isEnabled = false
					rehash.isEnabled = true
				} else if (manager.isPaused) {
                    start.isEnabled = true
                    pause.isEnabled = false
                    rehash.isEnabled = true
                } else {
                    start.isEnabled = false
                    pause.isEnabled = true
                    rehash.isEnabled = true
                }
            }
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if (identifier == "Files" &&
            Manager.getManagerByHash(hash: managerHash)?.state != Utils.torrentStates.Metadata.rawValue) {
            return true;
        }
        return false;
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "Files") {
            (segue.destination as! TorrentFilesController).managerHash = managerHash
            (segue.destination as! TorrentFilesController).name = title!
        }
    }
	
	@IBAction func seedingStateChanged(_ sender: UISwitch) {
		Manager.managerSaves[managerHash]?.seedMode = sender.isOn
		managerUpdated()
	}
	
    @IBAction func startAction(_ sender: UIBarButtonItem) {
        start_torrent(managerHash)
        start.isEnabled = false
        pause.isEnabled = true
    }
    
    @IBAction func pauseAction(_ sender: UIBarButtonItem) {
        stop_torrent(managerHash)
        start.isEnabled = true
        pause.isEnabled = false
    }
    
    @IBAction func rehashAction(_ sender: UIBarButtonItem) {
		let controller = ThemedUIAlertController(title: "Torrent rehash", message: "This action will recheck the state of all downloaded files", preferredStyle: .alert)
		let hash = UIAlertAction(title: "Rehash", style: .destructive) { _ in
			rehash_torrent(self.managerHash)
		}
		let cancel  = UIAlertAction(title: "Cancel", style: .cancel)
		controller.addAction(hash)
		controller.addAction(cancel)
		present(controller, animated: true)
    }
	
	@IBAction func removeTorrent(_ sender: UIBarButtonItem) {
		let manager = Manager.getManagerByHash(hash: managerHash)!
		let message = manager.hasMetadata ? "Are you sure to remove " + manager.title + " torrent?" : "Are you sure to remove this magnet torrent?"
		let removeController = ThemedUIAlertController(title: nil, message: message, preferredStyle: .actionSheet)
		let removeAll = UIAlertAction(title: "Yes and remove data", style: .destructive) { _ in
			self.removeTorrent(manager: manager, removeData: true)
		}
		let removeTorrent = UIAlertAction(title: "Yes but keep data", style: .default) { _ in
			self.removeTorrent(manager: manager)
		}
		let removeMagnet = UIAlertAction(title: "Remove", style: .destructive) { _ in
			self.removeTorrent(manager: manager, isMagnet: true)
		}
		let cancel = UIAlertAction(title: "Cancel", style: .cancel)
		if (!manager.hasMetadata) {
			removeController.addAction(removeMagnet)
		} else {
			removeController.addAction(removeAll)
			removeController.addAction(removeTorrent)
		}
		removeController.addAction(cancel)
		
		if (removeController.popoverPresentationController != nil) {
			removeController.popoverPresentationController?.barButtonItem = sender
			removeController.popoverPresentationController?.permittedArrowDirections = .down
		}
		
		present(removeController, animated: true)
	}
	
	
	
	func removeTorrent(manager: TorrentStatus, isMagnet: Bool = false, removeData: Bool = false) {
		remove_torrent(manager.hash, removeData ? 1 : 0)
		
		if (!isMagnet) {
			Manager.removeTorrentFile(hash: manager.hash)
			
			if (removeData) {
				if (FileManager.default.fileExists(atPath: Manager.rootFolder + "/" + manager.title)) {
					try! FileManager.default.removeItem(atPath: Manager.rootFolder + "/" + manager.title)
				}
			}
		}
		
		if (!(splitViewController?.isCollapsed)!) {
			let splitView = UIApplication.shared.keyWindow?.rootViewController as! UISplitViewController
			splitView.showDetailViewController(Utils.createEmptyViewController(), sender: self)
			
			print(splitView.viewControllers.count)
			if let nav = splitView.viewControllers.first as? UINavigationController,
				let view = nav.topViewController as? MainController {
				print("Conditions ")
				var indexPath: IndexPath?
				for i in 0 ..< view.managers.count {
					for j in 0 ..< view.managers[i].count {
						if (view.managers[i][j].hash == manager.hash) {
							indexPath = IndexPath(row: j, section: i)
						}
					}
				}
				if (indexPath != nil) {
					view.removeTorrent(indexPath: indexPath!, visualOnly: true)
				}
			}
		} else {
			navigationController?.popViewController(animated: true)
		}
	}
	
}
