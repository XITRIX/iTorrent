//
//  TorrentDetailsController.swift
//  iTorrent
//
//  Created by  XITRIX on 15.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

import MarqueeLabel

class TorrentDetailsController: ThemedUITableViewController {
	@IBOutlet weak var shareButton: UIBarButtonItem!
	
    @IBOutlet var segmentedProgressBar: SegmentedProgressView!
    @IBOutlet var progressBar: SegmentedProgressView!
    @IBOutlet var sequentialDownloadSwitcher: UISwitch!
    
	@IBOutlet weak var start: UIBarButtonItem!
    @IBOutlet weak var pause: UIBarButtonItem!
    @IBOutlet weak var rehash: UIBarButtonItem!
	@IBOutlet weak var switcher: UISwitch!
	@IBOutlet weak var seedLimitButton: UIButton!
	
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
	
	var seedLimitPickerView : SeedLimitPickerView!
	var myPickerView : UIPickerView!
    
    var sortedFilesData : [FilePieceData]!
    
    deinit {
        print("Details DEINIT")
    }
	
	override func themeUpdate() {
		super.themeUpdate()
		
		if let label = navigationItem.titleView as? UILabel {
			let theme = Themes.current()
			label.textColor = theme.mainText
		}
	}
    
    override func viewDidLoad() {
        super.viewDidLoad()
		if (managerHash == nil) {
			return
		}
        
        scrape_tracker(managerHash)
		
		let calendar = Calendar.current
		var saves = Manager.managerSaves[managerHash]
		if (saves == nil) {
			Manager.managerSaves[managerHash] = UserManagerSettings()
			saves = Manager.managerSaves[managerHash]
		}
		switcher.setOn((saves?.seedMode)! , animated: false)
		let date = saves?.addedDate ?? Date()
		addedOnLabel.text = String(calendar.component(.day, from: date)) + "/" + String(calendar.component(.month, from: date)) + "/" + String(calendar.component(.year, from: date))
		
		let limit = Manager.managerSaves[self.managerHash]?.seedLimit
		if (limit == 0) {
			seedLimitButton.setTitle(NSLocalizedString("Unlimited", comment: ""), for: .normal)
		} else {
			seedLimitButton.setTitle(Utils.getSizeText(size: limit!, decimals: true), for: .normal)
		}
		
		view.isUserInteractionEnabled = true
		tableView.isUserInteractionEnabled = true
		
		// MARQUEE LABEL
		let theme = Themes.current()
		let label = MarqueeLabel.init(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 44), duration: 8.0, fadeLength: 10)
		label.font = UIFont.boldSystemFont(ofSize: 17)
		label.textAlignment = NSTextAlignment.center
		label.textColor = theme.mainText
		navigationItem.titleView = label
        
        managerUpdated()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
		if (managerHash == nil) {
			return
		}
        
        managerUpdated()
		NotificationCenter.default.addObserver(self, selector: #selector(managerUpdated), name: .torrentsUpdated, object: nil)
    }
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		if (seedLimitPickerView != nil) {
			seedLimitPickerView.dismiss()
			seedLimitPickerView = nil
		}
	}
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
		
		NotificationCenter.default.removeObserver(self, name: .torrentsUpdated, object: nil)
    }
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		if (managerHash == nil) {
			return 0
		}
		return super.numberOfSections(in: tableView)
	}
	
	override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
		if (seedLimitPickerView != nil) {
			seedLimitPickerView.dismiss()
			seedLimitPickerView = nil
		}
	}
    
    @objc func managerUpdated() {
        if managerHash != nil,
            let manager = Manager.getManagerByHash(hash: managerHash) {
            let calendar = Calendar.current
            
            let totalDownloadProgress = manager.totalSize > 0 ? Float(manager.totalDone) / Float(manager.totalSize) : 0
            progressBar.setProgress([totalDownloadProgress])
            
            if (manager.hasMetadata) {
                setupPiecesFilter()
                
                segmentedProgressBar.setProgress(sortPiecesByFilesName(manager.pieces))
                sequentialDownloadSwitcher.setOn(manager.sequentialDownload, animated: false)
            }
            
            title = manager.title
            stateLabel.text = NSLocalizedString(manager.displayState, comment: "") 
            downloadLabel.text = Utils.getSizeText(size: Int64(manager.downloadRate)) + "/s"
            uploadLabel.text = Utils.getSizeText(size: Int64(manager.uploadRate)) + "/s"
            timeRemainsLabel.text = manager.displayState == Utils.torrentStates.Downloading.rawValue ? Utils.downloadingTimeRemainText(speedInBytes: Int64(manager.downloadRate), fileSize: manager.totalWanted, downloadedSize: manager.totalWantedDone) : "---"
            hashLabel.text = manager.hash.uppercased()
            creatorLabel.text = manager.creator
            createdOnLabel.text = String(calendar.component(.day, from: manager.creationDate!)) + "/" + String(calendar.component(.month, from: manager.creationDate!)) + "/" + String(calendar.component(.year, from: manager.creationDate!))
            commentsLabel.text = manager.comment
            selectedLabel.text = Utils.getSizeText(size: manager.totalWanted) + " / " + Utils.getSizeText(size: manager.totalSize)
            completedLabel.text = Utils.getSizeText(size: manager.totalWantedDone)
            progressLabel.text = String(format: "%.2f", Double(manager.totalWantedDone) / Double(manager.totalWanted) * 100) + "% / " + String(format: "%.2f", totalDownloadProgress * 100) + "%"
            downloadedLabel.text = Utils.getSizeText(size: manager.totalDownload)
            uploadedLabel.text = Utils.getSizeText(size: manager.totalUpload)
            seedersLabel.text = String(manager.numSeeds)
            peersLabel.text = String(manager.numPeers)
			
			switcher.setOn((Manager.managerSaves[managerHash]?.seedMode)! , animated: true)
			
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
			
			if let title = title {
				if FileManager.default.fileExists(atPath: Manager.configFolder + "/" + title + ".torrent") {
					shareButton.isEnabled = true
				}
				if let label = navigationItem.titleView as? UILabel {
					label.text = title + "        " 
				}
			} else {
				shareButton.isEnabled = false
			}
        }
    }
    
    func setupPiecesFilter() {
        if (sortedFilesData != nil) { return }
        let filesRaw = get_files_of_torrent_by_hash(managerHash)
        sortedFilesData = Array(UnsafeBufferPointer(start: filesRaw.files, count: Int(filesRaw.size)))
            .sorted{ (String(validatingUTF8: $0.file_name) ?? "ERROR") < (String(validatingUTF8: $1.file_name) ?? "ERROR") }
            .map{FilePieceData(name: String(validatingUTF8: $0.file_name) ?? "ERROR", beginIdx: $0.begin_idx, endIdx: $0.end_idx)}
    }
    
    func sortPiecesByFilesName(_ pieces : [Int32]) -> [CGFloat] {
        var res : [CGFloat] = []
        
        for i in sortedFilesData {
            for j in i.beginIdx ... i.endIdx {
                res.append(CGFloat(pieces[Int(j)]))
            }
        }
        
        return res
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if (identifier == "Files" &&
            Manager.getManagerByHash(hash: managerHash)?.state != Utils.torrentStates.Metadata.rawValue) {
            return true
        }
		if (identifier == "Trackers" &&
			Manager.getManagerByHash(hash: managerHash)?.state != Utils.torrentStates.Metadata.rawValue) {
			return true
		}
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "Files") {
            (segue.destination as! TorrentFilesController).managerHash = managerHash
            (segue.destination as! TorrentFilesController).name = title!
        }
		if (segue.identifier == "Trackers") {
			(segue.destination as! TrackersListController).managerHash = managerHash
		}
    }
    
    @IBAction func sequentialSwitcherChanged(_ sender: UISwitch) {
        set_torrent_files_sequental(managerHash, sender.isOn ? 1 : 0)
    }
    
	@IBAction func seedingStateChanged(_ sender: UISwitch) {
		Manager.managerSaves[managerHash]?.seedMode = sender.isOn
		if let manager = Manager.getManagerByHash(hash: managerHash) {
			if sender.isOn {
				if manager.isPaused {
					start_torrent(managerHash)
				}
				if (!UserDefaults.standard.bool(forKey: UserDefaultsKeys.backgroundSeedKey) &&
					!UserDefaults.standard.bool(forKey: UserDefaultsKeys.seedBackgroundWarning)) {
					let controller = ThemedUIAlertController(title: NSLocalizedString("Warning", comment: ""), message: NSLocalizedString("Seeding in background is disabled, if you will close this app, seeding will stop. Do you want to enable background seeding?\nIf seed limit is not set, then the app will countinue working in the background indefinitely, which may cause battery drain.", comment: ""), preferredStyle: .alert)
					let enable = UIAlertAction(title: NSLocalizedString("Enable", comment: ""), style: .destructive) { _ in
						UserDefaults.standard.set(true, forKey: UserDefaultsKeys.backgroundSeedKey)
					}
					let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { _ in
						UserDefaults.standard.set(true, forKey: UserDefaultsKeys.seedBackgroundWarning)
					}
					
					controller.addAction(enable)
					controller.addAction(cancel)
					
					present(controller, animated: true)
				}
			} else if !sender.isOn,
				manager.isPaused {
				stop_torrent(managerHash)
			}
		}
		Manager.mainLoop()
		managerUpdated()
	}
	
	@IBAction func seedLimitAction(_ sender: UIButton) {
		if (seedLimitPickerView == nil || seedLimitPickerView.dismissed) {
			seedLimitPickerView = SeedLimitPickerView(self, defaultValue: (Manager.managerSaves[self.managerHash]?.seedLimit)!, onStateChange: { res in
				Manager.managerSaves[self.managerHash]?.seedLimit = res
				if (res == 0) {
					sender.setTitle(NSLocalizedString("Unlimited", comment: ""), for: .normal)
				} else {
					sender.setTitle(Utils.getSizeText(size: res, decimals: true), for: .normal)
				}
			})
		}
	}
	
	@IBAction func sendTorrent(_ sender: UIBarButtonItem) {
		if let title = title {
            let controller = ThemedUIAlertController(title: nil, message: NSLocalizedString("Share", comment: ""), preferredStyle: .actionSheet)
            let file = UIAlertAction(title: NSLocalizedString("Torrent file", comment: ""), style: .default) { (action) in
                let stringPath = Manager.configFolder + "/" + title + ".torrent"
                if (FileManager.default.fileExists(atPath: stringPath)) {
                    let path = NSURL(fileURLWithPath: stringPath, isDirectory: false)
                    let shareController = ThemedUIActivityViewController(activityItems: [path], applicationActivities: nil)
                    if (shareController.popoverPresentationController != nil) {
                        shareController.popoverPresentationController?.barButtonItem = sender
                        shareController.popoverPresentationController?.permittedArrowDirections = .any
                    }
                    UIApplication.shared.keyWindow?.rootViewController?.present(shareController, animated: true)
                }
            }
            let magnet = UIAlertAction(title: NSLocalizedString("Magnet link", comment: ""), style: .default) { (action) in
                UIPasteboard.general.string = String(validatingUTF8: get_torrent_magnet_link(self.managerHash))
                let alert = ThemedUIAlertController(title: nil, message: NSLocalizedString("Magnet link copied to clipboard", comment: ""), preferredStyle: .alert)
                self.present(alert, animated: true, completion: nil)
                // change alert timer to 2 seconds, then dismiss
                let when = DispatchTime.now() + 2
                DispatchQueue.main.asyncAfter(deadline: when){
                    alert.dismiss(animated: true, completion: nil)
                }
            }
            let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)
            
            controller.addAction(file)
            controller.addAction(magnet)
            controller.addAction(cancel)
            
            if (controller.popoverPresentationController != nil) {
                controller.popoverPresentationController?.barButtonItem = sender
                controller.popoverPresentationController?.permittedArrowDirections = .up
            }
            
            present(controller, animated: true)
		}
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
		let controller = ThemedUIAlertController(title: NSLocalizedString("Torrent rehash", comment: ""), message: NSLocalizedString("This action will recheck the state of all downloaded files", comment: ""), preferredStyle: .alert)
		let hash = UIAlertAction(title: NSLocalizedString("Rehash", comment: ""), style: .destructive) { _ in
			rehash_torrent(self.managerHash)
		}
		let cancel  = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)
		controller.addAction(hash)
		controller.addAction(cancel)
		present(controller, animated: true)
    }
	
	@IBAction func removeTorrent(_ sender: UIBarButtonItem) {
		let manager = Manager.getManagerByHash(hash: managerHash)!
		let message = manager.hasMetadata ? "\(NSLocalizedString("Are you sure to remove", comment: "")) \( manager.title) \(NSLocalizedString("torrent", comment: ""))?" : NSLocalizedString("Are you sure to remove this magnet torrent?", comment: "")
		let removeController = ThemedUIAlertController(title: nil, message: message, preferredStyle: .actionSheet)
		let removeAll = UIAlertAction(title: NSLocalizedString("Yes and remove data", comment: ""), style: .destructive) { _ in
			self.removeTorrent(manager: manager, removeData: true)
		}
		let removeTorrent = UIAlertAction(title: NSLocalizedString("Yes but keep data", comment: ""), style: .default) { _ in
			self.removeTorrent(manager: manager)
		}
		let removeMagnet = UIAlertAction(title: NSLocalizedString("Remove", comment: ""), style: .destructive) { _ in
			self.removeTorrent(manager: manager, isMagnet: true)
		}
		let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)
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
