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
    var trackers: ReloadableSection<TrackerModel>!

    deinit {
        print("Trackers DEINIT!!")
    }

    @objc func update() {
        let raw = TorrentSdk.getTrackersByHash(hash: managerHash)
        let new = ReloadableSection<TrackerModel>(title: "", value: raw.enumerated().map { ReloadableCell<TrackerModel>(key: $1.url, value: $1, index: $0) }, index: 0)
        let diff = DiffCalculator.calculate(oldSectionItems: [trackers], newSectionItems: [new])
        trackers = new

        if diff.hasChanges() {
            tableView.beginUpdates()
            tableView.insertRows(at: diff.updates.inserts, with: .fade)
            tableView.deleteRows(at: diff.updates.deletes, with: .fade)
            tableView.endUpdates()
        }

        diff.updates.reloads.forEach { indexPath in
            if let cell = tableView.cellForRow(at: indexPath) as? TrackerCell {
                cell.setModel(tracker: new.value[indexPath.row].value)
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

        trackers = ReloadableSection<TrackerModel>(title: "", value: [], index: 0)
        update()
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
                UIPasteboard.general.string = trackers.value[index.row].value.url
                Dialog.withTimer(self, title: nil, message: Localize.get("Tracker URL copied to clipboard!"))
            }
        }
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

            Utils.checkFolderExist(path: Core.configFolder)

            if let _ = URL(string: textField.text!) {
                print(TorrentSdk.addTrackerToTorrent(hash: self.managerHash, trackerUrl: textField.text!))
                self.update()
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
                self.trackers.value[$0.row].value.url
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
        trackers.value.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? TrackerCell {
            cell.setModel(tracker: trackers.value[indexPath.row].value)
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
