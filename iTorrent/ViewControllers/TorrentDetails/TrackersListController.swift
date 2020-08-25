//
//  TrackersListController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 02/07/2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import ITorrentFramework
import DeepDiff
import Foundation
import UIKit

class TrackersListController: ThemedUIViewController {
    override var toolBarIsHidden: Bool? {
        !tableView.isEditing
    }

    @IBOutlet var tableView: ThemedUITableView!
    @IBOutlet var addButton: UIBarButtonItem!
    @IBOutlet var removeButton: UIBarButtonItem!

    var managerHash: String!
    var trackers: [TrackerModel] = []

    deinit {
        print("Trackers DEINIT!!")
    }

    @objc func update() {
        let new = TorrentSdk.getTrackersByHash(hash: managerHash)
        let changes = diff(old: trackers, new: new) 
        trackers = new

        let res = IndexPathConverter().convert(changes: changes, section: 0)

        if changes.count > 0 {
            tableView.unifiedPerformBatchUpdates({
                if res.inserts.count > 0 { tableView.insertRows(at: res.inserts, with: .fade) }
                if res.deletes.count > 0 { tableView.deleteRows(at: res.deletes, with: .fade) }
            }, completion: nil)
        }

        res.replaces.forEach { indexPath in
            if let cell = tableView.cellForRow(at: indexPath) as? TrackerCell {
                cell.setModel(tracker: new[indexPath.row])
            }
        }
    }

    override func themeUpdate() {
        super.themeUpdate()
        tableView.backgroundColor = Themes.current.backgroundMain
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        TorrentSdk.scrapeTracker(hash: managerHash)

        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.dataSource = self
        tableView.delegate = self

        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPress(longPressGestureRecognizer:)))
        view.addGestureRecognizer(longPressRecognizer)

        trackers = TorrentSdk.getTrackersByHash(hash: managerHash)
        tableView.reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(update), name: .mainLoopTick, object: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .mainLoopTick, object: nil)
    }

    @objc func longPress(longPressGestureRecognizer: UILongPressGestureRecognizer) {
        if longPressGestureRecognizer.state == .began {
            let touchPoint = longPressGestureRecognizer.location(in: tableView)
            if let index = tableView.indexPathForRow(at: touchPoint) {
                UIPasteboard.general.string = trackers[index.row].url
                Dialog.withTimer(self, title: nil, message: Localize.get("Tracker's URL copied to clipboard!"))
            }
        }
    }

    @IBAction func editAction(_ sender: UIBarButtonItem) {
        let editing = !tableView.isEditing
        tableView.setEditing(editing, animated: true)
        navigationController?.setToolbarHidden(toolBarIsHidden ?? false, animated: true)
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
        Dialog.withTextField(self, title: "Add Tracker", message: "Enter the full tracker's URL",
                             textFieldConfiguration: { textField in
                                 textField.placeholder = NSLocalizedString("Tracker's URL", comment: "")
        }, okText: "Add") { textField in
            Utils.checkFolderExist(path: Core.configFolder)

            if let _ = URL(string: textField.text!) {
                print(TorrentSdk.addTrackerToTorrent(hash: self.managerHash, trackerUrl: textField.text!))
                self.update()
            } else {
                Dialog.show(self, title: "Error", message: "Wrong link, check it and try again!")
            }
        }
    }

    @IBAction func removeAction(_ sender: UIBarButtonItem) {
        let controller = ThemedUIAlertController(title: nil, message: NSLocalizedString("Are you shure to remove this trackers?", comment: ""), preferredStyle: .actionSheet)
        let remove = UIAlertAction(title: NSLocalizedString("Remove", comment: ""), style: .destructive) { _ in
            let urls: [String] = self.tableView.indexPathsForSelectedRows!.map {
                self.trackers[$0.row].url
            }

            _ = TorrentSdk.removeTrackersFromTorrent(hash: self.managerHash, trackerUrls: urls)
            self.update()
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
        navigationController?.setToolbarHidden(toolBarIsHidden ?? false, animated: true)
    }
}
