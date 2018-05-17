//
//  TorrentDetailsController.swift
//  iTorrent
//
//  Created by  XITRIX on 15.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class TorrentDetailsController: UITableViewController, ManagersUpdatedDelegate {
    @IBOutlet weak var start: UIBarButtonItem!
    @IBOutlet weak var pause: UIBarButtonItem!
    @IBOutlet weak var rehash: UIBarButtonItem!
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        managerUpdated()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        managerUpdated()
        Manager.managersUpdatedDelegates.append(self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        Manager.managersUpdatedDelegates = Manager.managersUpdatedDelegates.filter({$0 !== (self as ManagersUpdatedDelegate)})
    }
    
    func managerUpdated() {
        if managerHash != nil,
            let manager = Manager.getManagerByHash(hash: managerHash) {
            let calendar = Calendar.current
            
            title = manager.title
            stateLabel.text = manager.displayState
            downloadLabel.text = Utils.getSizeText(size: Int64(manager.downloadRate)) + "/s"
            uploadLabel.text = Utils.getSizeText(size: Int64(manager.uploadRate)) + "/s"
            timeRemainsLabel.text = manager.state == Utils.torrentStates.Downloading.rawValue ? Utils.downloadingTimeRemainText(speedInBytes: Int64(manager.downloadRate), fileSize: manager.totalWanted, downloadedSize: manager.totalWantedDone) : "---"
            hashLabel.text = manager.hash.uppercased()
            creatorLabel.text = manager.creator
            createdOnLabel.text = String(calendar.component(.day, from: manager.creationDate!)) + "/" + String(calendar.component(.month, from: manager.creationDate!)) + "/" + String(calendar.component(.year, from: manager.creationDate!))
            //addedOnLabel.text =
            commentsLabel.text = manager.comment
            selectedLabel.text = Utils.getSizeText(size: manager.totalWanted) + " / " + Utils.getSizeText(size: manager.totalSize)
            completedLabel.text = Utils.getSizeText(size: manager.totalWantedDone)
            progressLabel.text = String(format: "%.2f", Double(manager.totalWantedDone) / Double(manager.totalWanted) * 100) + "% / " + String(format: "%.2f", Double(manager.totalDone) / Double(manager.totalSize) * 100) + "%"
            downloadedLabel.text = Utils.getSizeText(size: manager.totalDownload)
            uploadedLabel.text = Utils.getSizeText(size: manager.totalUpload)
            seedersLabel.text = String(manager.numSeeds)
            peersLabel.text = String(manager.numPeers)
            
            print(manager.isPaused)
            print(manager.isFinished)
            print(manager.isSeed)
            //print(manager.seedMode)
            print("------------")
            
            if (manager.state == Utils.torrentStates.Hashing.rawValue) {
                start.isEnabled = false
                pause.isEnabled = false
                rehash.isEnabled = false
            } else {
                if (manager.isPaused) {
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
    }
}
