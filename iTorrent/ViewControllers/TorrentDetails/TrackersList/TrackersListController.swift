//
//  TrackersListController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 02/07/2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

#if TRANSMISSION
import ITorrentTransmissionFramework
#else
import ITorrentFramework
#endif

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

        tableView.cellLayoutMarginsFollowReadableWidth = true
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
        
         Dialog.withTextView(self,
                             title: "Add Trackers",
                             message: "Enter tracker URLs separated by blank line",
                             textViewConfiguration: { textView in
                                 textView.placeholder = NSLocalizedString("Ex: http://x.x.x.x:8080/announce", comment: "")
                             },
                             okText: "Add") { textView in
            
                Utils.checkFolderExist(path: Core.configFolder)

                let result = self.parseTorrentTrackersList(textView.text!)
                let validTrackers = result.0
                let processedEntries = result.1
                if validTrackers.isEmpty {
                    Dialog.show(self, title: "Error", message: "No valid tracker URLs found!\n     processed: \(processedEntries)")
                } else {
                    var added_count:Int = 0
                    for tracker in validTrackers {
                        let added:Bool = TorrentSdk.addTrackerToTorrent(hash: self.managerHash, trackerUrl: tracker)
                        if(added){ added_count+=1 }
                        print("Added Tracker: \(added) trackerUrl: \(tracker)")
                    }
                    if(validTrackers.count < processedEntries || added_count < validTrackers.count ){
                        Dialog.show(self, title: "Warning", message: "Some entries were duplicate/invalid!\n processed: \(processedEntries) added: \(added_count)")
                    }
                    self.update()
                }
        }
    }
    
    func isValidTrackerURL(_ url: String) -> Bool {
        // Regular expression pattern to validate a tracker URL
        let pattern = "^(http|https|udp)://[A-Za-z0-9.-]+(:[0-9]+)?(/[A-Za-z0-9.-]+)*(/[A-Za-z0-9?=&.-]+)*$"
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let range = NSRange(location: 0, length: url.utf16.count)
            if let _ = regex.firstMatch(in: url, options: [], range: range) {
                if let _ = URL(string: url) {
                    return true
                }
            }
        }
        
        return false
    }

    func parseTorrentTrackersList(_ input: String) -> ([String],Int) {
        // Split the input string into lines, removing empty lines and trimming spaces
        let entries = input
            .components(separatedBy: .newlines)
            .count
        let lines = input
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        // Filter out the valid tracker URLs
        let validTrackers = lines.filter { isValidTrackerURL($0) }
        
        return (validTrackers, entries)
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
        tableView.isEditing
    }

    func tableView(_ tableView: UITableView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        setEditing(true, animated: true)
        navigationController?.setToolbarHidden(toolBarIsHidden ?? false, animated: true)
    }
}
