//
//  AddTorrentController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 31.03.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit
import MarqueeLabel

class AddTorrentController: ThemedUIViewController {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var weightLabel: UIBarButtonItem!
    
    deinit {
        print("AddTorrentController: deinit")
    }

    var filePath: String = ""
    var path: URL!

    var fileProvider: FileProviderTableDataSource!
    var files: [FileModel]!
    var name: String = ""

    func initialize(filePath: String, path: URL = URL(string: "/")!, name: String = "", files: [FileModel]! = nil) {
        self.filePath = filePath
        self.files = files
        self.name = name
        self.path = path
    }

    override func themeUpdate() {
        super.themeUpdate()
        tableView.backgroundColor = Themes.current.backgroundMain
        weightLabel.tintColor = Themes.current.secondaryText

        if let label = navigationItem.titleView as? UILabel {
            let theme = Themes.current
            label.textColor = theme.mainText
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if files == nil {
            let temp = TorrentSdk.getFilesOfTorrentByPath(path: filePath)!
            files = temp.files
            name = temp.title
            files.forEach({$0.priority = .normalPriority})
            
            // MARQUEE LABEL
            let theme = Themes.current
            let label = MarqueeLabel(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 44), duration: 8.0, fadeLength: 10)
            label.font = UIFont.boldSystemFont(ofSize: 17)
            label.textAlignment = NSTextAlignment.center
            label.textColor = theme.mainText
            label.text = name + "        "
            navigationItem.titleView = label

            navigationController?.presentationController?.delegate = self
        } else {
            navigationItem.leftBarButtonItem = nil
        }

        if let oldManager = Core.shared.torrents.values.filter({ $0.title == name }).first {
            let controller = ThemedUIAlertController(title: Localize.get("Torrent update detected"),
                                                     message: "\(Localize.get("Torrent with name")) \(name)" +
                                                         "\(Localize.get("already exists, do you want to apply previous files selection settings to this torrent"))?",
                                                     preferredStyle: .alert)
            let apply = UIAlertAction(title: NSLocalizedString("Apply", comment: ""), style: .default) { _ in
                let oldFiles = TorrentSdk.getFilesOfTorrentByHash(hash: oldManager.hash)!

                for file in self.files {
                    if let oldFile = oldFiles.filter({ $0.name == file.name }).first {
                        file.priority = oldFile.priority
                    }
                }

                self.tableView.reloadData()
            }
            let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)

            controller.addAction(apply)
            controller.addAction(cancel)

            present(controller, animated: true)
        }

        if path.pathComponents.count > 1 {
            let titleView = FileManagerTitleView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 44))
            titleView.title.text = path.lastPathComponent
            titleView.subTitle.text = path.deletingLastPathComponent().path
            navigationItem.titleView = titleView
        }

        fileProvider = FileProviderTableDataSource(tableView: tableView, path: path, data: files)
        fileProvider.delegate = self

        tableView.dataSource = fileProvider
        tableView.delegate = fileProvider

        updateWeightLabel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateWeightLabel()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    @IBAction func cancelAction(_ sender: Any) {
        if FileManager.default.fileExists(atPath: Core.configFolder + "/_temp.torrent") {
            try? FileManager.default.removeItem(atPath: Core.configFolder + "/_temp.torrent")
        }
        FullscreenAd.shared.load()
        dismiss(animated: true)
    }

    @IBAction func selectAllAction(_ sender: Any) {
        fileProvider.selectAll()
        updateWeightLabel()
    }

    @IBAction func deselectAllAction(_ sender: Any) {
        fileProvider.deselectAll()
        updateWeightLabel()
    }

    @IBAction func downloadAction(_ sender: Any) {
        if downloadingWeight() >= MemorySpaceManager.freeDiskSpaceInBytes {
            let alert = ThemedUIAlertController(title: Localize.get("AddTorrentController.MemoryWarning.Title"),
                                                message: Localize.get("AddTorrentController.MemoryWarning.Message"),
                                                preferredStyle: .alert)

            let addAnyway = UIAlertAction(title: Localize.get("AddTorrentController.MemoryWarning.AddAnyway"), style: .destructive) { _ in
                self.addTorrentToDownload()
            }
            let cancel = UIAlertAction(title: Localize.get("Cancel"), style: .cancel)

            alert.addAction(addAnyway)
            alert.addAction(cancel)

            present(alert, animated: true)

            return
        }

        addTorrentToDownload()
    }

    func addTorrentToDownload() {
        let urlPath = URL(fileURLWithPath: filePath)
        let urlRes = urlPath.deletingLastPathComponent().appendingPathComponent(name + ".torrent")
        if FileManager.default.fileExists(atPath: urlRes.path) {
            try? FileManager.default.removeItem(at: urlRes)
        }
        if let old = Core.shared.torrents.values.first(where: { $0.title == name }) {
            TorrentSdk.removeTorrent(hash: old.hash, withFiles: false)
        }

        do {
            try FileManager.default.copyItem(at: urlPath, to: urlRes)
            if filePath.hasSuffix("_temp.torrent") {
                try FileManager.default.removeItem(atPath: Core.configFolder + "/_temp.torrent")
            }
            dismiss(animated: true)
            if let hash = TorrentSdk.getTorrentFileHash(torrentPath: urlRes.path) {
                TorrentSdk.addTorrent(torrentPath: urlRes.path, states: files.map { $0.priority })
                Core.shared.torrentsUserData[hash] = UserManagerSettings()
            }
        } catch {
            let controller = ThemedUIAlertController(title: NSLocalizedString("Error has been occured", comment: ""), message: error.localizedDescription, preferredStyle: .alert)
            let close = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .cancel)
            controller.addAction(close)
            present(controller, animated: true)
        }
        FullscreenAd.shared.load()
    }

    func updateWeightLabel() {
        weightLabel.title = Utils.getSizeText(size: downloadingWeight())
    }

    func downloadingWeight() -> Int64 {
        files.filter { $0.priority != .dontDownload }.map { $0.size }.reduce(0, +)
    }
}

extension AddTorrentController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        if FileManager.default.fileExists(atPath: Core.configFolder + "/_temp.torrent") {
            try? FileManager.default.removeItem(atPath: Core.configFolder + "/_temp.torrent")
        }
        FullscreenAd.shared.load()
    }
}

extension AddTorrentController: FileProviderDelegate {
    func fileSelected(file: FileModel) {
        updateWeightLabel()
    }

    func folderSelected(folder: FolderModel) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "AddTorrentView") as! AddTorrentController
        vc.initialize(filePath: filePath, path: folder.path, name: name, files: files)
        show(vc, sender: self)
    }

    func folderPriorityChanged(folder: FolderModel) {
        updateWeightLabel()
    }

    func fileActionCalled(file: FileModel) {
        updateWeightLabel()
    }
}
