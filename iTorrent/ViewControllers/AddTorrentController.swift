//
//  AddTorrentController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 31.03.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

#if TRANSMISSION
import ITorrentTransmissionFramework
#else
import ITorrentFramework
#endif

import MarqueeLabel
import UIKit

class AddTorrentController: ThemedUIViewController {
    var cancelButton: UIBarButtonItem!
    var downloadButton: UIBarButtonItem!
    var selectAllButton: UIBarButtonItem!
    var deselectAllButton: UIBarButtonItem!
    var weightLabel: UIBarButtonItem!
    
    var tableView: UITableView!
    
    deinit {
        print("AddTorrentController: deinit")
    }

    var filePath: String = ""
    var path: URL!

    var fileProvider: FileProviderTableDataSource!
    var files: [FileModel]!
    var name: String = ""
    
    override var toolBarIsHidden: Bool? {
        false
    }
    
    init(filePath: String, path: URL = URL(string: "/")!, name: String = "", files: [FileModel]! = nil) {
        super.init()
        
        self.filePath = filePath
        self.files = files
        self.name = name
        self.path = path
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    
    override func loadView() {
        super.loadView()
        
        tableView = ThemedUITableView(frame: view.frame)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(tableView)
        
        selectAllButton = UIBarButtonItem(title: "TorrentFilesController.SelectAll".localized, style: .plain, target: self, action: #selector(selectAllAction))
        selectAllButton.tintColor = .systemBlue
        deselectAllButton = UIBarButtonItem(title: "TorrentFilesController.DeselectAll".localized, style: .plain, target: self, action: #selector(deselectAllAction))
        deselectAllButton.tintColor = .systemRed
        weightLabel = UIBarButtonItem(title: nil, style: .plain, target: nil, action: nil)
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbarItems = [deselectAllButton, space, weightLabel, space, selectAllButton]
        
        cancelButton = UIBarButtonItem(title: "Cancel".localized, style: .plain, target: self, action: #selector(cancelAction))
        navigationItem.setLeftBarButton(cancelButton, animated: false)
        
        downloadButton = UIBarButtonItem(title: "Download".localized, style: .done, target: self, action: #selector(downloadAction))
        navigationItem.setRightBarButton(downloadButton, animated: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if files == nil {
            let temp = TorrentSdk.getFilesOfTorrentByPath(path: filePath)!
            files = temp.files
            name = temp.title
            files.forEach { $0.priority = .normalPriority }

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
            Dialog.withButton(self,
                              title: "Torrent update detected",
                              message: "\(Localize.get("Torrent with name")) \(name)" +
                                  "\(Localize.get("already exists, do you want to apply previous files selection settings to this torrent"))?",
                              okTitle: "Apply") {
                let oldFiles = TorrentSdk.getFilesOfTorrentByHash(hash: oldManager.hash)!

                for file in self.files {
                    if let oldFile = oldFiles.filter({ $0.name == file.name }).first {
                        file.priority = oldFile.priority
                    }
                }

                self.tableView.reloadData()
            }
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

    @IBAction func cancelAction() {
        if FileManager.default.fileExists(atPath: Core.tempFile) {
            try? FileManager.default.removeItem(atPath: Core.tempFile)
        }
        #if !targetEnvironment(macCatalyst)
        FullscreenAd.shared.load()
        #endif
        dismiss(animated: true)
    }

    @IBAction func selectAllAction() {
        fileProvider.selectAll()
        updateWeightLabel()
    }

    @IBAction func deselectAllAction() {
        fileProvider.deselectAll()
        updateWeightLabel()
    }

    @IBAction func downloadAction() {
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
                try FileManager.default.removeItem(atPath: Core.tempFile)
            }
            dismiss(animated: true)
            if let hash = TorrentSdk.getTorrentFileHash(torrentPath: urlRes.path) {
                TorrentSdk.addTorrent(torrentPath: urlRes.path, states: files.map { $0.priority })
                Core.shared.torrentsUserData[hash] = UserManagerSettings()
            }
        } catch {
            Dialog.show(self, title: "Error has been occured", message: error.localizedDescription)
        }
        
        #if !targetEnvironment(macCatalyst)
        FullscreenAd.shared.load()
        #endif
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
        if FileManager.default.fileExists(atPath: Core.tempFile) {
            try? FileManager.default.removeItem(atPath: Core.tempFile)
        }
        
        #if !targetEnvironment(macCatalyst)
        FullscreenAd.shared.load()
        #endif
    }
}

extension AddTorrentController: FileProviderDelegate {
    func fileSelected(file: FileModel) {
        updateWeightLabel()
    }

    func folderSelected(folder: FolderModel) {
        let vc = AddTorrentController(filePath: filePath, path: folder.path, name: name, files: files)
        show(vc, sender: self)
    }

    func folderPriorityChanged(folder: FolderModel) {
        updateWeightLabel()
    }

    func fileActionCalled(file: FileModel) {
        updateWeightLabel()
    }
}
