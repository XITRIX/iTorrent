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
    @IBOutlet var shareButton: UIBarButtonItem!

    @IBOutlet var segmentedProgressBar: SegmentedProgressView!
    @IBOutlet var progressBar: SegmentedProgressView!
    @IBOutlet var sequentialDownloadSwitcher: UISwitch!

    @IBOutlet var start: UIBarButtonItem!
    @IBOutlet var pause: UIBarButtonItem!
    @IBOutlet var rehash: UIBarButtonItem!
    @IBOutlet var switcher: UISwitch!
    @IBOutlet var seedLimitButton: UIButton!

    @IBOutlet var stateLabel: UILabel!
    @IBOutlet var downloadLabel: UILabel!
    @IBOutlet var uploadLabel: UILabel!
    @IBOutlet var timeRemainsLabel: UILabel!
    @IBOutlet var hashLabel: UILabel!
    @IBOutlet var creatorLabel: UILabel!
    @IBOutlet var createdOnLabel: UILabel!
    @IBOutlet var addedOnLabel: UILabel!
    @IBOutlet var commentsLabel: UILabel!
    @IBOutlet var selectedLabel: UILabel!
    @IBOutlet var completedLabel: UILabel!
    @IBOutlet var progressLabel: UILabel!
    @IBOutlet var downloadedLabel: UILabel!
    @IBOutlet var uploadedLabel: UILabel!
    @IBOutlet var seedersLabel: UILabel!
    @IBOutlet var peersLabel: UILabel!

    @IBOutlet var trackersButtonLabel: UILabel!
    @IBOutlet var filesButtonLabel: UILabel!

    var managerHash: String!

    var seedLimitPickerView: SizePicker?
    var myPickerView: UIPickerView!

    var sortedFilesData: [FilePieceData]!

    var useInsertStyle: Bool {
        return !(splitViewController?.isCollapsed ?? true)
    }

    deinit {
        print("Details DEINIT")
    }

    override func themeUpdate() {
        super.themeUpdate()

        if let label = navigationItem.titleView as? UILabel {
            let theme = Themes.current
            label.textColor = theme.mainText
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if managerHash == nil {
            return
        }

        TorrentSdk.scrapeTracker(hash: managerHash)

        let calendar = Calendar.current
        var saves = Core.shared.torrentsUserData[managerHash]
        if saves == nil {
            Core.shared.torrentsUserData[managerHash] = UserManagerSettings()
            saves = Core.shared.torrentsUserData[managerHash]
        }
        switcher.setOn((saves?.seedMode)!, animated: false)
        let date = saves?.addedDate ?? Date()
        addedOnLabel.textWithFit = String(calendar.component(.day, from: date)) + "/" + String(calendar.component(.month, from: date)) + "/" + String(calendar.component(.year, from: date))

        let limit = Core.shared.torrentsUserData[managerHash]?.seedLimit
        if limit == 0 {
            seedLimitButton.setTitle(NSLocalizedString("Unlimited", comment: ""), for: .normal)
        } else {
            seedLimitButton.setTitle(Utils.getSizeText(size: limit!, decimals: true), for: .normal)
        }

        view.isUserInteractionEnabled = true
        tableView.isUserInteractionEnabled = true

        trackersButtonLabel.textWithFit = NSLocalizedString("Trackers", comment: "")
        filesButtonLabel.textWithFit = NSLocalizedString("Files", comment: "")

        // MARQUEE LABEL
        let theme = Themes.current
        let label = MarqueeLabel(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 44), duration: 8.0, fadeLength: 10)
        label.font = UIFont.boldSystemFont(ofSize: 17)
        label.textAlignment = NSTextAlignment.center
        label.textColor = theme.mainText
        label.trailingBuffer = 44
        navigationItem.titleView = label

        managerUpdated()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if managerHash == nil {
            return
        }

        managerUpdated()
        NotificationCenter.default.addObserver(self, selector: #selector(managerUpdated), name: .mainLoopTick, object: nil)
        navigationController?.isToolbarHidden = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        seedLimitPickerView?.dismiss()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .mainLoopTick, object: nil)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        if managerHash == nil {
            return 0
        }
        return super.numberOfSections(in: tableView)
    }

    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        seedLimitPickerView?.dismiss()
    }

    @objc func managerUpdated() {
        if managerHash != nil,
            let manager = Core.shared.torrents[managerHash] {
            let calendar = Calendar.current

            let totalDownloadProgress = manager.totalSize > 0 ? Float(manager.totalDone) / Float(manager.totalSize) : 0
            progressBar.setProgress([totalDownloadProgress])

            if manager.hasMetadata {
                setupPiecesFilter()

                // Very large torrents cause "ladder" effect (lags) while scrolling on running in main thread
                DispatchQueue.global(qos: .background).async { [weak self] in
                    let pieces = self?.sortPiecesByFilesName(manager.pieces)
                    DispatchQueue.main.async {
                        if let self = self,
                            let pieces = pieces {
                            self.segmentedProgressBar.setProgress(pieces)
                        }
                    }
                }
                sequentialDownloadSwitcher.setOn(manager.sequentialDownload, animated: false)
            }

            title = manager.title
            stateLabel.textWithFit = NSLocalizedString(manager.displayState.rawValue, comment: "")
            downloadLabel.textWithFit = Utils.getSizeText(size: Int64(manager.downloadRate)) + "/s"
            uploadLabel.textWithFit = Utils.getSizeText(size: Int64(manager.uploadRate)) + "/s"
            timeRemainsLabel.textWithFit = manager.displayState == .downloading ?
                Utils.downloadingTimeRemainText(speedInBytes: Int64(manager.downloadRate), fileSize: manager.totalWanted, downloadedSize: manager.totalWantedDone) :
                "---"
            hashLabel.textWithFit = manager.hash.uppercased()
            creatorLabel.textWithFit = manager.creator
            createdOnLabel.textWithFit = String(calendar.component(.day, from: manager.creationDate!)) + "/" +
                String(calendar.component(.month, from: manager.creationDate!)) + "/" +
                String(calendar.component(.year, from: manager.creationDate!))
            commentsLabel.textWithFit = manager.comment
            selectedLabel.textWithFit = Utils.getSizeText(size: manager.totalWanted) + " / " + Utils.getSizeText(size: manager.totalSize)
            completedLabel.textWithFit = Utils.getSizeText(size: manager.totalWantedDone)
            progressLabel.textWithFit = String(format: "%.2f", manager.totalWanted == 0 ? 0 :
                Double(manager.totalWantedDone) / Double(manager.totalWanted) * 100) + "% / " +
                String(format: "%.2f", totalDownloadProgress * 100) + "%"
            downloadedLabel.textWithFit = Utils.getSizeText(size: manager.totalDownload)
            uploadedLabel.textWithFit = Utils.getSizeText(size: manager.totalUpload)
            seedersLabel.textWithFit = String(manager.numSeeds)
            peersLabel.textWithFit = String(manager.numPeers)

            switcher.setOn(Core.shared.torrentsUserData[managerHash]!.seedMode, animated: true)

            if manager.state == .hashing ||
                manager.state == .metadata {
                start.isEnabled = false
                pause.isEnabled = false
                rehash.isEnabled = false
            } else {
                if manager.isFinished, !switcher.isOn {
                    start.isEnabled = false
                    pause.isEnabled = false
                    rehash.isEnabled = true
                } else if manager.isPaused {
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
                if FileManager.default.fileExists(atPath: Core.configFolder + "/" + title + ".torrent") {
                    shareButton.isEnabled = true
                }
                if let label = navigationItem.titleView as? UILabel {
                    label.text = title
                }
            } else {
                shareButton.isEnabled = false
            }
        }
    }

    override func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        indexPath.section == 4 && (indexPath.row == 0 || indexPath.row == 1 || indexPath.row == 4)
    }

    override func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        action == #selector(UIResponderStandardEditActions.copy(_:))
    }

    override func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) {
        if let cell = tableView.cellForRow(at: indexPath) as? DetailCell {
            UIPasteboard.general.string = cell.details?.text ?? ""
        }
    }

    func setupPiecesFilter() {
        if sortedFilesData != nil {
            return
        }
        sortedFilesData = TorrentSdk.getFilesOfTorrentByHash(hash: managerHash)!
            .sorted(by: { $0.name < $1.name })
            .map { FilePieceData(name: $0.name, beginIdx: $0.beginIdx, endIdx: $0.endIdx) }
    }

    func sortPiecesByFilesName(_ pieces: [Int]) -> [CGFloat] {
        var res: [CGFloat] = []

        for file in sortedFilesData {
            for piece in file.beginIdx...file.endIdx {
                res.append(CGFloat(pieces[Int(piece)]))
            }
        }

        return res
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "Files",
            Core.shared.torrents[managerHash]?.state != .metadata {
            return true
        }
        if identifier == "Trackers",
            Core.shared.torrents[managerHash]?.state != .metadata {
            return true
        }
        return false
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Files" {
            (segue.destination as? TorrentFilesController)?.initialize(torrentHash: managerHash)
        }
        if segue.identifier == "Trackers" {
            (segue.destination as? TrackersListController)?.managerHash = managerHash
        }
    }

    @IBAction func sequentialSwitcherChanged(_ sender: UISwitch) {
        TorrentSdk.setTorrentFilesSequential(hash: managerHash, sequential: sender.isOn)
    }

    @IBAction func seedingStateChanged(_ sender: UISwitch) {
        Core.shared.torrentsUserData[managerHash]?.seedMode = sender.isOn
        if let manager = Core.shared.torrents[managerHash] {
            if manager.isPaused {
                TorrentSdk.startTorrent(hash: managerHash)
            }

            if sender.isOn {
                if UserPreferences.background &&
                    !UserPreferences.backgroundSeedKey &&
                    !UserPreferences.seedBackgroundWarning {
                    UserPreferences.seedBackgroundWarning = true

                    let controller = ThemedUIAlertController(title: Localize.get("Warning"),
                                                             message: Localize.get("Details.BackgroundSeeding.Warning"),
                                                             preferredStyle: .alert)
                    let enable = UIAlertAction(title: NSLocalizedString("Enable", comment: ""), style: .destructive) { _ in
                        UserPreferences.backgroundSeedKey = true
                    }
                    let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)

                    controller.addAction(enable)
                    controller.addAction(cancel)

                    present(controller, animated: true)
                }
            } else if !sender.isOn,
                manager.isPaused {
                TorrentSdk.stopTorrent(hash: managerHash)
            }
        }
        Core.shared.mainLoop()
        managerUpdated()
    }

    @IBAction func seedLimitAction(_ sender: UIButton) {
        seedLimitPickerView?.dismiss()
        seedLimitPickerView = SizePicker(defaultValue: Core.shared.torrentsUserData[managerHash]!.seedLimit, dataSelected: { res in
            Core.shared.torrentsUserData[self.managerHash]?.seedLimit = res
            if res == 0 {
                sender.setTitle(NSLocalizedString("Unlimited", comment: ""), for: .normal)
            } else {
                sender.setTitle(Utils.getSizeText(size: res, decimals: true), for: .normal)
            }
        })
        seedLimitPickerView?.show(navigationController!)
    }

    @IBAction func sendTorrent(_ sender: UIBarButtonItem) {
        if let title = title {
            let controller = ThemedUIAlertController(title: nil, message: NSLocalizedString("Share", comment: ""), preferredStyle: .actionSheet)
            let file = UIAlertAction(title: NSLocalizedString("Torrent file", comment: ""), style: .default) { _ in
                let stringPath = Core.configFolder + "/" + title + ".torrent"
                if FileManager.default.fileExists(atPath: stringPath) {
                    let path = NSURL(fileURLWithPath: stringPath, isDirectory: false)
                    let shareController = ThemedUIActivityViewController(activityItems: [path], applicationActivities: nil)
                    if shareController.popoverPresentationController != nil {
                        shareController.popoverPresentationController?.barButtonItem = sender
                        shareController.popoverPresentationController?.permittedArrowDirections = .any
                    }
                    Utils.topViewController?.present(shareController, animated: true)
                }
            }
            let magnet = UIAlertAction(title: NSLocalizedString("Magnet link", comment: ""), style: .default) { _ in
                UIPasteboard.general.string = TorrentSdk.getTorrentMagnetLink(hash: self.managerHash)
                let alert = ThemedUIAlertController(title: nil, message: NSLocalizedString("Magnet link copied to clipboard", comment: ""), preferredStyle: .alert)
                self.present(alert, animated: true, completion: nil)
                // change alert timer to 2 seconds, then dismiss
                let when = DispatchTime.now() + 2
                DispatchQueue.main.asyncAfter(deadline: when) {
                    alert.dismiss(animated: true, completion: nil)
                }
            }
            let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)

            controller.addAction(file)
            controller.addAction(magnet)
            controller.addAction(cancel)

            if controller.popoverPresentationController != nil {
                controller.popoverPresentationController?.barButtonItem = sender
                controller.popoverPresentationController?.permittedArrowDirections = .up
            }

            present(controller, animated: true)
        }
    }

    @IBAction func startAction(_ sender: UIBarButtonItem) {
        TorrentSdk.startTorrent(hash: managerHash)
        start.isEnabled = false
        pause.isEnabled = true
    }

    @IBAction func pauseAction(_ sender: UIBarButtonItem) {
        TorrentSdk.stopTorrent(hash: managerHash)
        start.isEnabled = true
        pause.isEnabled = false
    }

    @IBAction func rehashAction(_ sender: UIBarButtonItem) {
        let controller = ThemedUIAlertController(title: Localize.get("Torrent rehash"),
                                                 message: Localize.get("This action will recheck the state of all downloaded files"),
                                                 preferredStyle: .alert)
        let hash = UIAlertAction(title: NSLocalizedString("Rehash", comment: ""), style: .destructive) { _ in
            TorrentSdk.rehashTorrent(hash: self.managerHash)
        }
        let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)
        controller.addAction(hash)
        controller.addAction(cancel)
        present(controller, animated: true)
    }

    @IBAction func removeTorrent(_ sender: UIBarButtonItem) {
        Core.shared.removeTorrentsUI(hashes: [managerHash], sender: sender, direction: .down) {
            if !self.splitViewController!.isCollapsed,
                let splitView = UIApplication.shared.keyWindow?.rootViewController as? UISplitViewController {
                splitView.showDetailViewController(Utils.createEmptyViewController(), sender: self)

                print(splitView.viewControllers.count)
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    // LOGIC FOR TABLEVIEW INSET STYLE
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass {
            tableView.reloadData()
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let res = super.tableView(tableView, titleForHeaderInSection: section) {
            return "\(useInsertStyle ? "      " : "")\(res)"
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let res = super.tableView(tableView, cellForRowAt: indexPath) as! ThemedUITableViewCell
        res.insetStyle = useInsertStyle
        if useInsertStyle {
            res.setInsetParams(tableView: tableView, indexPath: indexPath)
        }
        return res
    }
}
