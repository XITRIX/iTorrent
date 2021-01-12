//
//  TorrentDetailsControllerNew.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 02.08.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import ITorrentFramework
import MarqueeLabel
import UIKit

class TorrentDetailsController: StaticTableViewController {
    private var onScreenPopup: PopupViewController?

    override var toolBarIsHidden: Bool? {
        onScreenPopup != nil
    }

    var toolbarButtons: (share: UIBarButtonItem,
                         start: UIBarButtonItem,
                         pause: UIBarButtonItem,
                         rehash: UIBarButtonItem,
                         remove: UIBarButtonItem)!
    var manager: TorrentModel!
    var managerHash: String! {
        didSet { manager = Core.shared.torrents[managerHash] }
    }

    override var useInsertStyle: Bool {
        !(splitViewController?.isCollapsed ?? true)
    }

    deinit {
        print("Deinit: TorrentDetailsControllerNew")
    }

    override func themeUpdate() {
        super.themeUpdate()

        if let label = navigationItem.titleView as? UILabel {
            let theme = Themes.current
            label.textColor = theme.mainText
        }
    }

    override func loadView() {
        super.loadView()
        tableView.register(DoubleProgressCell.nib, forCellReuseIdentifier: DoubleProgressCell.name)
        tableView.register(DetailCell.nib, forCellReuseIdentifier: DetailCell.name)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupToolBar()

//        TorrentSdk.scrapeTracker(hash: managerHash)

        title = "Back".localized

        // MARQUEE LABEL
        let theme = Themes.current
        let label = MarqueeLabel(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 44), duration: 8.0, fadeLength: 10)
        label.font = UIFont.boldSystemFont(ofSize: 17)
        label.textAlignment = NSTextAlignment.center
        label.textColor = theme.mainText
        label.trailingBuffer = 44
        navigationItem.titleView = label
    }

    override func initSections() {
        weak var weakSelf = self

        // STATE
        var state = [CellModelProtocol]()
        state.append(DetailCell.Model(title: "Details.State", detail: { weakSelf?.manager.displayState.rawValue }))
        data.append(Section(rowModels: state))

        // SPEED
        var speed = [CellModelProtocol]()
        speed.append(DetailCell.Model(title: "Details.Speed.Download", detail: { Utils.getSizeText(size: Int64(weakSelf?.manager.downloadRate ?? 0)) + "/s" }))
        speed.append(DetailCell.Model(title: "Details.Speed.Upload", detail: { Utils.getSizeText(size: Int64(weakSelf?.manager.uploadRate ?? 0)) + "/s" }))
        speed.append(DetailCell.Model(title: "Details.Speed.Remains", detail: {
            weakSelf?.manager.displayState == .downloading ?
                Utils.downloadingTimeRemainText(speedInBytes: Int64(weakSelf?.manager.downloadRate ?? 0), fileSize: weakSelf?.manager.totalWanted ?? 0, downloadedSize: weakSelf?.manager.totalWantedDone ?? 0) :
                "---"
        }))
        data.append(Section(rowModels: speed, header: "Details.Speed.Title"))

        // DOWNLOAD
        var download = [CellModelProtocol]()
        download.append(SwitchCell.Model(title: "Details.Downloading.Sequential", bold: true, defaultValue: { weakSelf?.manager.sequentialDownload }, action: { sender in
            TorrentSdk.setTorrentFilesSequential(hash: weakSelf?.managerHash ?? "", sequential: sender.isOn)
        }))
        download.append(DoubleProgressCell.Model(title: "Details.Downloading.Progress", torrentModel: { weakSelf?.manager }))
        data.append(Section(rowModels: download, header: "Details.Downloading.Title"))

        // UPLOAD
        var upload = [CellModelProtocol]()
        upload.append(SwitchCell.Model(title: "Details.Seeding.Allow", bold: true, defaultValue: { weakSelf?.manager.seedMode }, action: { sender in
            weakSelf?.seedingStateChanged(sender)
        }))
        upload.append(ButtonCell.Model(title: "Details.Seeding.Limit",
                                       bold: true,
                                       buttonTitleFunc: {
                                           weakSelf?.manager.seedLimit == 0 ?
                                               "Unlimited".localized :
                                               Utils.getSizeText(size: weakSelf?.manager.seedLimit, decimals: true)
                                       }) { button in
                weakSelf?.onScreenPopup?.dismiss()
                weakSelf?.onScreenPopup = SizePicker(defaultValue: Int64(Core.shared.torrentsUserData[weakSelf?.managerHash ?? ""]?.seedLimit ?? 0), dataSelected: { res in
                    if let hash = weakSelf?.managerHash {
                        Core.shared.torrentsUserData[hash]?.seedLimit = res
                        if res == 0 {
                            button.setTitle("Unlimited".localized, for: .normal)
                        } else {
                            button.setTitle(Utils.getSizeText(size: res, decimals: true), for: .normal)
                        }
                    }
                }, dismissAction: { _ in
                    weakSelf?.onScreenPopup = nil
                    if let hidden = weakSelf?.toolBarIsHidden {
                        weakSelf?.navigationController?.setToolbarHidden(hidden, animated: true)
                    }
                })
                weakSelf?.navigationController?.setToolbarHidden(true, animated: true)

                guard let self = weakSelf else { return }
                self.onScreenPopup?.show(in: self)
            })
        data.append(Section(rowModels: upload, header: "Details.Seeding.Title"))

        // MAIN INFORMATION
        var mainInformation = [CellModelProtocol]()
        mainInformation.append(DetailCell.Model(title: "Details.Info.Hash", detail: { weakSelf?.manager.hash }, longPressAction: {
            UIPasteboard.general.string = weakSelf?.manager.hash
            Dialog.withTimer(weakSelf, title: "\("Details.Info.Hash".localized) \("copied".localized)")
        }))
        mainInformation.append(DetailCell.Model(title: "Details.Info.Creator", detail: { weakSelf?.manager.creator },
                                                hiddenCondition: { weakSelf?.manager.creator.isEmpty ?? true }, longPressAction: {
                                                    UIPasteboard.general.string = weakSelf?.manager.creator
                                                    Dialog.withTimer(weakSelf, title: "\("Details.Info.Creator".localized) \("copied".localized)")
                                                }))
        mainInformation.append(DetailCell.Model(title: "Details.Info.Created", detail: { weakSelf?.manager.creationDate?.simpleDate() }))
        mainInformation.append(DetailCell.Model(title: "Details.Info.Added", detail: { weakSelf?.manager.addedDate?.simpleDate() }))
        mainInformation.append(DetailCell.Model(title: "Details.Info.Comment", detail: { weakSelf?.manager.comment },
                                                hiddenCondition: { weakSelf?.manager.comment.isEmpty ?? true }, longPressAction: {
                                                    UIPasteboard.general.string = weakSelf?.manager.comment
                                                    Dialog.withTimer(weakSelf, title: "\("Details.Info.Comment".localized) \("copied".localized)")
                                                }))
        data.append(Section(rowModels: mainInformation, header: "Details.Info.Title"))

        // TRANSFER
        var transfer = [CellModelProtocol]()
        transfer.append(DetailCell.Model(title: "Details.Transfer.Total", detail: { Utils.getSizeText(size: weakSelf?.manager.totalWanted) + " / " + Utils.getSizeText(size: weakSelf?.manager.totalSize) }))
        transfer.append(DetailCell.Model(title: "Details.Transfer.Completed", detail: { Utils.getSizeText(size: weakSelf?.manager.totalWantedDone) }))
        transfer.append(DetailCell.Model(title: "Details.Transfer.Progress", detail: {
            let totalDownloadProgress = (weakSelf?.manager.totalSize ?? 0) > 0 ? Float(weakSelf?.manager.totalDone ?? 0) / Float(weakSelf?.manager.totalSize ?? 0) : 0
            return String(format: "%.2f", weakSelf?.manager.totalWanted == 0 ? 0 :
                Double(weakSelf?.manager.totalWantedDone ?? 0 * 100) / Double(weakSelf?.manager.totalWanted ?? 0)) + "% / " +
                String(format: "%.2f", totalDownloadProgress * 100) + "%"
        }))
        transfer.append(DetailCell.Model(title: "Details.Transfer.Downloaded", detail: { Utils.getSizeText(size: weakSelf?.manager.totalDownload) }))
        transfer.append(DetailCell.Model(title: "Details.Transfer.Uploaded", detail: { Utils.getSizeText(size: weakSelf?.manager.totalUpload) }))
        transfer.append(DetailCell.Model(title: "Details.Transfer.Seeders", detail: { "\(weakSelf?.manager.numSeeds ?? 0) (\(weakSelf?.manager.numTotalSeeds ?? 0))" }))
        transfer.append(DetailCell.Model(title: "Details.Transfer.Leechers", detail: { "\(weakSelf?.manager.numLeechers ?? 0) (\(weakSelf?.manager.numTotalLeechers ?? 0))" }))
        data.append(Section(rowModels: transfer, header: "Details.Transfer.Title"))

        // MORE
        var more = [CellModelProtocol]()
        more.append(SegueCell.Model(title: "Details.More.Trackers",
                                    bold: true,
                                    tapAction: {
                                        if weakSelf?.manager.state != .metadata {
                                            let vc = Utils.instantiate("TrackersListController") as TrackersListController
                                            vc.managerHash = weakSelf?.managerHash
                                            weakSelf?.show(vc, sender: weakSelf)
                                        }
                                    }))
        more.append(SegueCell.Model(title: "Details.More.Files",
                                    bold: true,
                                    tapAction: {
                                        if weakSelf?.manager.state != .metadata,
                                            let hash = weakSelf?.managerHash
                                        {
                                            let vc = TorrentFilesController(hash: hash)
                                            weakSelf?.show(vc, sender: weakSelf)
                                        }
                                    }))
        data.append(Section(rowModels: more, header: "Details.More.Title"))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        managerUpdated()
        NotificationCenter.default.addObserver(self, selector: #selector(managerUpdated), name: .mainLoopTick, object: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .mainLoopTick, object: nil)
    }

    @objc func managerUpdated() {
        updateData()

        if manager.state == .hashing ||
            manager.state == .metadata
        {
            toolbarButtons.start.isEnabled = false
            toolbarButtons.pause.isEnabled = false
            toolbarButtons.rehash.isEnabled = false
        } else {
            if manager.isFinished, !manager.seedMode {
                toolbarButtons.start.isEnabled = false
                toolbarButtons.pause.isEnabled = false
                toolbarButtons.rehash.isEnabled = true
            } else if manager.isPaused {
                toolbarButtons.start.isEnabled = true
                toolbarButtons.pause.isEnabled = false
                toolbarButtons.rehash.isEnabled = true
            } else {
                toolbarButtons.start.isEnabled = false
                toolbarButtons.pause.isEnabled = true
                toolbarButtons.rehash.isEnabled = true
            }
        }

        toolbarButtons.share.isEnabled = FileManager.default.fileExists(atPath: Core.configFolder + "/" + manager.title + ".torrent")

        // Update title
        if let label = navigationItem.titleView as? UILabel {
            label.text = manager.title
        }
    }

    func seedingStateChanged(_ sender: UISwitch) {
        Core.shared.torrentsUserData[managerHash]?.seedMode = sender.isOn
        if let manager = Core.shared.torrents[managerHash] {
            if sender.isOn {
                if UserPreferences.background &&
                    !UserPreferences.backgroundSeedKey &&
                    !UserPreferences.seedBackgroundWarning
                {
                    UserPreferences.seedBackgroundWarning = true

                    let controller = ThemedUIAlertController(title: "Warning".localized,
                                                             message: "Details.BackgroundSeeding.Warning".localized,
                                                             preferredStyle: .alert)
                    let enable = UIAlertAction(title: "Enable".localized, style: .destructive) { _ in
                        UserPreferences.backgroundSeedKey = true
                    }
                    let cancel = UIAlertAction(title: "Cancel".localized, style: .cancel)

                    controller.addAction(enable)
                    controller.addAction(cancel)

                    present(controller, animated: true)
                }
            } else if !sender.isOn,
                manager.isFinished,
                !manager.isPaused
            {
                TorrentSdk.stopTorrent(hash: managerHash)
            }
        }
        Core.shared.mainLoop()
    }

    func setupToolBar() {
        var share: UIBarButtonItem
        if #available(iOS 14.0, *) {
            share = UIBarButtonItem(title: nil, image: #imageLiteral(resourceName: "Share"), primaryAction: nil, menu: shareMenu())
        } else {
            share = UIBarButtonItem(image: #imageLiteral(resourceName: "Share"), style: .plain, target: self, action: #selector(shareAction))
        }

        let start = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(startAction))
        let pause = UIBarButtonItem(barButtonSystemItem: .pause, target: self, action: #selector(pauseAction))
        let rehash = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(rehashAction))
        let remove = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(removeAction))
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)

        toolbarButtons = (share: share, start: start, pause: pause, rehash: rehash, remove: remove)

        navigationItem.setRightBarButton(share, animated: false)
        toolbarItems = [start, space, pause, space, rehash, space, space, space, space, remove]
    }

    @objc func startAction() {
        TorrentSdk.startTorrent(hash: managerHash)
        Core.shared.mainLoop()
    }

    @objc func pauseAction() {
        TorrentSdk.stopTorrent(hash: managerHash)
        Core.shared.mainLoop()
    }

    @objc func rehashAction() {
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

    @objc func removeAction() {
        Core.shared.removeTorrentsUI(hashes: [managerHash], sender: toolbarButtons.remove, direction: .down) {
            if !(self.splitViewController?.isCollapsed ?? true),
                let splitView = UIApplication.shared.keyWindow?.rootViewController as? UISplitViewController
            {
                splitView.showDetailViewController(Utils.createEmptyViewController(), sender: self)

                print(splitView.viewControllers.count)
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }

    func shareFile() {
        if let title = Core.shared.torrents[managerHash]?.title {
            let stringPath = Core.configFolder + "/" + title + ".torrent"
            if FileManager.default.fileExists(atPath: stringPath) {
                let path = NSURL(fileURLWithPath: stringPath, isDirectory: false)
                let shareController = ThemedUIActivityViewController(activityItems: [path], applicationActivities: nil)
                if shareController.popoverPresentationController != nil {
                    shareController.popoverPresentationController?.barButtonItem = toolbarButtons.share
                    shareController.popoverPresentationController?.permittedArrowDirections = .any
                }
                Utils.topViewController?.present(shareController, animated: true)
            }
        }
    }

    func shareMagnet() {
        UIPasteboard.general.string = TorrentSdk.getTorrentMagnetLink(hash: managerHash)
        Dialog.withTimer(self, message: "Magnet link copied to clipboard")
    }

    @available(iOS 13.0, *)
    func shareMenu() -> UIMenu {
        UIMenu(title: "Share".localized, children: [
            UIAction(title: "Torrent file".localized, image: UIImage(systemName: "doc.fill"), handler: { _ in self.shareFile() }),
            UIAction(title: "Magnet link".localized, image: UIImage(systemName: "link"), handler: { _ in self.shareMagnet() })
        ])
    }

    @objc func shareAction() {
        let controller = ThemedUIAlertController(title: nil, message: NSLocalizedString("Share", comment: ""), preferredStyle: .actionSheet)
        let file = UIAlertAction(title: NSLocalizedString("Torrent file", comment: ""), style: .default) { _ in
            self.shareFile()
        }
        let magnet = UIAlertAction(title: NSLocalizedString("Magnet link", comment: ""), style: .default) { _ in
            self.shareMagnet()
        }
        let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)

        controller.addAction(file)
        controller.addAction(magnet)
        controller.addAction(cancel)

        if controller.popoverPresentationController != nil {
            controller.popoverPresentationController?.barButtonItem = toolbarButtons.share
            controller.popoverPresentationController?.permittedArrowDirections = .up
        }

        present(controller, animated: true)
    }
}
