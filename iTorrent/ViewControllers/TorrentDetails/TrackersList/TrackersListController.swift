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
            // perform add trackers on a background thread and show progress/result on UI
            self.performAddTrackers(textView.text!){
                self.update()
            }
        }
    }
    
    private func performAddTrackers(_ trackers: String, postAddActions: (()->Void)?){
        
        let progressViewController = ProgressViewController()
        // show progress bar on UI Thread and continue until dismissed
        progressViewController.showProgress(presenter: self)
    
        // perform task as async in non-UI (background) Thread
        DispatchQueue.global().async {
            var totalProgress:Float = 100.0

            Utils.checkFolderExist(path: Core.configFolder)
            
            // parse and retrive valid tracker URLs
            let consumed:Float = 40.0                   // following operation can update progress by +40
            totalProgress -= consumed
            let result = self.parseTorrentTrackersList(trackers, progressViewController, allowedProgress: consumed)
            
            let validTrackers = result.validTrackers
            let processedEntries = result.entries
            
            var title,message,stats: String
            
            if(validTrackers.isEmpty){
                title       = "Error"
                message     = "No valid tracker URLs found!"
                stats       = "processed: \(processedEntries.count)"
            } else {
                let consumed:Float = 10.0                   // following operation can update progress by +10
                totalProgress -= consumed
                let trackerUrls = TorrentSdk
                    .getTrackersByHash(hash: self.managerHash)
                    .map{ trackerInfo in
                        trackerInfo.url
                    }
                let uniqueTrackers = validTrackers.filter { !trackerUrls.contains($0) }
                // update the progress
                progressViewController.setProgress(progressViewController.getProgress()+consumed)
                
                // trackerUrls
                let increment = (totalProgress/Float(uniqueTrackers.count))
                var added_count:Int = 0
                for tracker in uniqueTrackers {
                    let added:Bool = TorrentSdk.addTrackerToTorrent(hash: self.managerHash, trackerUrl: tracker)
                    if(added){ added_count += 1 }
                    print("\(added_count). Added Tracker: \(added) trackerUrl: \(tracker)")
                    // update progress for each operation
                    progressViewController.setProgress(progressViewController.getProgress()+increment)
                }
                print("Total Trackers Added: \(added_count)")
                stats = "processed: \(processedEntries.count) added: \(added_count)"
                
                title   = "Warning"
                if(validTrackers.count == processedEntries.count && uniqueTrackers.count == 0){
                    message = "All entries were duplicates!"
                }else if(validTrackers.count == processedEntries.count && uniqueTrackers.count < validTrackers.count){
                    message = "Some entries were duplicates!"
                }else if(validTrackers.count < processedEntries.count && uniqueTrackers.count == validTrackers.count){
                    message = "Some entries were invalid!"
                }else if(validTrackers.count < processedEntries.count && uniqueTrackers.count < validTrackers.count){
                    message = "Some entries were duplicate/invalid!"
                }else{
                    // validTrackers.count == processedEntries.count == uniqueTrackers.count
                    title   = "Info"
                    message = "All valid tracker URLs were added!"
                }
            }
            progressViewController.consumeRemainingPercentage()    // complete progress to 100 on UI Thread
            // hide progress on UI Thread
            progressViewController.hideProgress(animated: false) {
                // do post add tasks
                Dialog.show(self, title: title, message: "\(message)\n\(stats)")
                postAddActions?()
            }
        }
    }
    
    private func isValidTrackerURL(_ url: String) -> Bool {
        // Regular expression pattern to validate a tracker URL
        let scheme              = #"https?|udp|ftp|torrent|magnet|ws|wss"#
        let port                = #":[0-9]+"#
        let ipv4_addr_domain    = #"[0-9A-Za-z.-]+"#                       // ipv4 addr or domain names
        let ipv6_addr           = #"\[?[0-9A-Fa-f:]+\]?"#                  // ipv6 addr
        let path                = #"(/[A-Za-z0-9.-]+)*"#
        
        let pattern = "^(\(scheme))://(\(ipv4_addr_domain)|\(ipv6_addr))(\(port))?\(path)?$"
        
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

    private func parseTorrentTrackersList(_ input: String,
                                          _ pvc: ProgressViewController,
                                          allowedProgress: Float = 100.0
    ) -> (validTrackers: [String], entries: [String], lines: Int) {
        // Split the input string into lines, removing empty lines and trimming spaces
        let lines: [String] = input.components(separatedBy: .newlines)
        let entries = lines
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        // update progress status
        let consumed:Float = 5
        let remaining:Float = allowedProgress - consumed
        pvc.setProgress(pvc.getProgress()+consumed)         // bump progress by 5 percentage
        
        let increment = (remaining/Float(entries.count))
        // Filter out the valid tracker URLs (remove duplicates if any by passing through set)
        let validTrackers = Array(Set(entries.filter {
            let validity = isValidTrackerURL($0)
            pvc.setProgress(pvc.getProgress()+increment)    // update the progress
            return validity
        }))
        print("parseTorrentTrackersList() progress: \(pvc.getProgress())")
        return (validTrackers, entries, lines.count)
    }

    @IBAction func removeAction(_ sender: UIBarButtonItem) {
        let controller = ThemedUIAlertController(title: nil, message: NSLocalizedString("Are you sure to remove this trackers?", comment: ""), preferredStyle: .actionSheet)
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
