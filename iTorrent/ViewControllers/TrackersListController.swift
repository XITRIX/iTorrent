//
//  TrackersListController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 02/07/2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class TrackersListController : ThemedUIViewController, UITableViewDataSource, UITableViewDelegate {
	
	@IBOutlet weak var tableView: ThemedUITableView!
	@IBOutlet weak var addButton: UIBarButtonItem!
	@IBOutlet weak var removeButton: UIBarButtonItem!
	
	var managerHash: String!
	var trackers : [Tracker] = []
	var runUpdate = true
	
	deinit {
		print("Trackers DEINIT!!")
	}
	
	func update() {
		trackers.removeAll()
		
		let trackersRaw = get_trackers_by_hash(managerHash)
		let urlArr = Array(UnsafeBufferPointer(start: trackersRaw.tracker_url, count: Int(trackersRaw.size)))
		//let msgArr = Array(UnsafeBufferPointer(start: trackersRaw.messages, count: Int(trackersRaw.size)))
		for i in 0 ..< Int(trackersRaw.size) {
			let tracker = Tracker()
			tracker.url = String(validatingUTF8: urlArr[i]!) ?? "ERROR"
			var msg = trackersRaw.working[i] == 1 ? NSLocalizedString("Working", comment: "") : NSLocalizedString("Inactive", comment: "")
			if (trackersRaw.verified[i] == 1) {
				msg += ", " + NSLocalizedString("Verified", comment: "")
			}
			tracker.message = msg
			tracker.peers = Int(trackersRaw.peers[i])
			tracker.seeders = Int(trackersRaw.seeders[i])
			trackers.append(tracker)
		}
	}
	
	override func themeUpdate() {
		super.themeUpdate()
		tableView.backgroundColor = Themes.current().backgroundMain
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		DispatchQueue.global(qos: .background).async {
			while(self.runUpdate) {
				let previousCount = self.trackers.count
				self.update()
				DispatchQueue.main.async {
					if (previousCount == self.trackers.count) {
						for cell in self.tableView.visibleCells {
							if let cell = cell as? TrackerCell {
								let index = (self.tableView.indexPath(for: cell)?.row)!
								cell.title.text = self.trackers[index].url
								cell.message.text = self.trackers[index].message
								cell.peers.text = "" //"Peers: \(trackers[indexPath.row].peers)"
								cell.seeders.text = "Seeds: \(self.trackers[index].seeders)"
							}
						}
					} else {
						self.tableView.reloadData()
					}
				}
				sleep(1)
			}
		}
		
		tableView.rowHeight = 64
		tableView.dataSource = self
		tableView.delegate = self
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		runUpdate = false
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return trackers.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TrackerCell
		cell.title.text = trackers[indexPath.row].url
		cell.message.text = trackers[indexPath.row].message
		cell.peers.text = "" //"Peers: \(trackers[indexPath.row].peers)"
		cell.seeders.text = "Seeds: \(trackers[indexPath.row].seeders)"
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if let paths = tableView.indexPathsForSelectedRows,
			paths.count > 0 {
			removeButton.isEnabled = true
		}
	}
	
	func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
		if let paths = tableView.indexPathsForSelectedRows,
			paths.count == 0 {
			removeButton.isEnabled = false
		} else {
			removeButton.isEnabled = false
		}
	}
	
	@IBAction func editAction(_ sender: UIBarButtonItem) {
		let alertController = ThemedUIAlertController(title: NSLocalizedString("Sorry", comment: ""), message: NSLocalizedString("This action will be available in future updates", comment: ""), preferredStyle: .alert)
		let close = UIAlertAction(title: "OK", style: .cancel)
		alertController.addAction(close)
		self.present(alertController, animated: true)
		
		//Uncomment when will be able to add or remove trackers
//		let editing = !tableView.isEditing
//		tableView.setEditing(editing, animated: true)
//		if let toolbarItems = toolbarItems,
//			!editing {
//			for item in toolbarItems {
//				item.isEnabled = false
//			}
//		} else {
//			addButton.isEnabled = true
//		}
//		sender.title = editing ? "Done" : "Edit"
//		sender.style = editing ? .done : .plain
	}
	
	@IBAction func addAction(_ sender: UIBarButtonItem) {
		let controller = ThemedUIAlertController(title: NSLocalizedString("Add Tracker", comment: ""), message: NSLocalizedString("Enter the full tracker's URL", comment: ""), preferredStyle: .alert)
		controller.addTextField(configurationHandler: { (textField) in
			textField.placeholder = NSLocalizedString("Tracker's URL", comment: "")
			textField.keyboardAppearance = Themes.current().keyboardAppearence
		})
		let add = UIAlertAction(title: NSLocalizedString("Add", comment: ""), style: .default) { _ in
			let textField = controller.textFields![0]
			
			Utils.checkFolderExist(path: Manager.configFolder)
			
			if let _ = URL(string: textField.text!) {
				print(add_tracker_to_torrent(self.managerHash, textField.text))
			} else {
				let alertController = ThemedUIAlertController(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Wrong link, check it and try again!", comment: ""), preferredStyle: .alert)
				let close = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .cancel)
				alertController.addAction(close)
				self.present(alertController, animated: true)
			}
		}
		let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)
		
		controller.addAction(add)
		controller.addAction(cancel)
		
		present(controller, animated: true)
	}
	
	@IBAction func removeAction(_ sender: UIBarButtonItem) {
		
	}
}

class Tracker {
	var url = ""
	var message = ""
	var seeders = 0
	var peers = 0
}
