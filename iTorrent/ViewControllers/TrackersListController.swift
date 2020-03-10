//
//  TrackersListController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 02/07/2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class TrackersListController: ThemedUIViewController {
    @IBOutlet var tableView: ThemedUITableView!
    @IBOutlet var addButton: UIBarButtonItem!
    @IBOutlet var removeButton: UIBarButtonItem!

    var managerHash: String!
    var trackers: [Tracker] = []
    var runUpdate = true

    deinit {
        print("Trackers DEINIT!!")
    }

    func update() {
        var localTrackers: [Tracker] = []
        let trackersRaw = get_trackers_by_hash(managerHash)
        for iter in 0..<Int(trackersRaw.size) {
            var tracker = Tracker()
            tracker.url = String(validatingUTF8: trackersRaw.tracker_url[iter]) ?? "ERROR"
            var msg = trackersRaw.working[iter] == 1 ? NSLocalizedString("Working", comment: "") : NSLocalizedString("Inactive", comment: "")
            if trackersRaw.verified[iter] == 1 {
                msg += ", " + NSLocalizedString("Verified", comment: "")
            }
            tracker.message = msg
            tracker.peers = Int(trackersRaw.peers[iter])
            tracker.seeders = Int(trackersRaw.seeders[iter])
            tracker.leechs = Int(trackersRaw.leechs[iter])
            localTrackers.append(tracker)
        }
        trackers = localTrackers
    }

    override func themeUpdate() {
        super.themeUpdate()
        tableView.backgroundColor = Themes.current.backgroundMain
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        scrape_tracker(managerHash)
        DispatchQueue.global(qos: .background).async {
            while self.runUpdate {
                let oldDataset = self.trackers
                self.update()
                DispatchQueue.main.async {
                    if oldDataset.count == self.trackers.count {
                        var reloadIndexes = [IndexPath]()
                        for iter in 0..<self.trackers.count {
                            if oldDataset[iter] != self.trackers[iter] {
                                reloadIndexes.append(IndexPath(row: iter, section: 0))
                            }
                        }
                        if reloadIndexes.count > 0 {
                            self.tableView.reloadRows(at: reloadIndexes, with: .automatic)
                        }
                    } else {
                        self.tableView.reloadSections([0], with: .automatic)
                    }
                }
                sleep(1)
            }
        }
        
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.dataSource = self
        tableView.delegate = self
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        runUpdate = false
    }

    @IBAction func editAction(_ sender: UIBarButtonItem) {
        let editing = !tableView.isEditing
        tableView.setEditing(editing, animated: true)
        if let toolbarItems = toolbarItems,
            !editing {
            for item in toolbarItems {
                item.isEnabled = false
            }
        } else {
            addButton.isEnabled = true
        }
        sender.title = editing ? NSLocalizedString("Done", comment: "") : NSLocalizedString("Edit", comment: "")
        sender.style = editing ? .done : .plain
    }

    @IBAction func addAction(_ sender: UIBarButtonItem) {
        let controller = ThemedUIAlertController(title: NSLocalizedString("Add Tracker", comment: ""), message: NSLocalizedString("Enter the full tracker's URL", comment: ""), preferredStyle: .alert)
        controller.addTextField(configurationHandler: { textField in
            textField.placeholder = NSLocalizedString("Tracker's URL", comment: "")
            textField.keyboardAppearance = Themes.current.keyboardAppearence
        })
        let add = UIAlertAction(title: NSLocalizedString("Add", comment: ""), style: .default) { _ in
            let textField = controller.textFields![0]

            Utils.checkFolderExist(path: Manager.configFolder)

            if let _ = URL(string: textField.text!) {
                print(add_tracker_to_torrent(self.managerHash, textField.text))
            } else {
                let alertController = ThemedUIAlertController(title: Localize.get("Error"),
                                                              message: Localize.get("Wrong link, check it and try again!"),
                                                              preferredStyle: .alert)
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
        let controller = ThemedUIAlertController(title: nil, message: NSLocalizedString("Are you shure to remove this trackers?", comment: ""), preferredStyle: .actionSheet)
        let remove = UIAlertAction(title: NSLocalizedString("Remove", comment: ""), style: .destructive) { _ in
            let urls: [String] = self.tableView.indexPathsForSelectedRows!.map {
                self.trackers[$0.row].url
            }

            _ = Utils.withArrayOfCStrings(urls) { args in
                remove_tracker_from_torrent(self.managerHash, args, Int32(urls.count))
            }
        }
        let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)

        controller.addAction(remove)
        controller.addAction(cancel)

        if controller.popoverPresentationController != nil {
            controller.popoverPresentationController?.barButtonItem = sender
            controller.popoverPresentationController?.permittedArrowDirections = .down
        }

        present(controller, animated: true)
    }
}

extension TrackersListController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        trackers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? TrackerCell {
            cell.setModel(tracker: trackers[indexPath.row])
            return cell
        }
        return UITableViewCell()
    }
}

extension TrackersListController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let paths = tableView.indexPathsForSelectedRows,
            paths.count > 0 {
            removeButton.isEnabled = true
        } else {
            removeButton.isEnabled = false
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let paths = tableView.indexPathsForSelectedRows,
            paths.count > 0 {
            removeButton.isEnabled = true
        } else {
            removeButton.isEnabled = false
        }
    }

    func tableView(_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        return tableView.isEditing
    }

    func tableView(_ tableView: UITableView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        setEditing(true, animated: true)
    }
}

struct Tracker: Equatable {
    var url = ""
    var message = ""
    var seeders = 0
    var peers = 0
    var leechs = 0
}
