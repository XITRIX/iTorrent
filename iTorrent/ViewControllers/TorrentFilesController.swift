//
//  TorrentFilesController2.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 31.03.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

class TorrentFilesController: ThemedUIViewController {
    static let filesUpdatedNotification = NSNotification.Name(rawValue: "filesUpdatedNotification")
    
    @IBOutlet var editButton: UIBarButtonItem!
    @IBOutlet var selectAllButton: UIBarButtonItem!
    @IBOutlet var deselectAllButton: UIBarButtonItem!
    
    @IBOutlet var tableView: ThemedUITableView!
    
    var torrentHash: String = ""
    var fileProvider: FileProviderTableDataSource!
    var files: [FileModel]!
    var path: URL!
    
    func initialize(torrentHash: String, path: URL = URL(string: "/")!, files: [FileModel]! = nil) {
        self.torrentHash = torrentHash
        self.files = files
        self.path = path
    }
    
    func localize() {
        editButton.title = Localize.get("TorrentFilesController.Edit")
        selectAllButton.title = Localize.get("TorrentFilesController.SelectAll")
        deselectAllButton.title = Localize.get("TorrentFilesController.DeselectAll")
    }
    
    override func themeUpdate() {
        super.themeUpdate()
        tableView.backgroundColor = Themes.current.backgroundMain
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        localize()
        
        // until I realise what I want to do with it
        navigationItem.rightBarButtonItem = nil
        
        if files == nil {
            files = TorrentSdk.getFilesOfTorrentByHash(hash: torrentHash)!
        }
        
        if path.pathComponents.count > 1 {
            let titleView = FileManagerTitleView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 44))
            titleView.title.text = path.lastPathComponent
            titleView.subTitle.text = path.deletingLastPathComponent().path
            navigationItem.titleView = titleView
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(updateData), name: .mainLoopTick, object: nil)
        }
        
        fileProvider = FileProviderTableDataSource(tableView: tableView, path: path, data: files)
        fileProvider.delegate = self
        
        tableView.dataSource = fileProvider
        tableView.delegate = fileProvider
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(updateUI), name: TorrentFilesController.filesUpdatedNotification, object: nil)
    }
    
    @objc func updateData() {
        DispatchQueue.global(qos: .utility).async { [files] in
            guard let files = files else { return }
            if let upd = TorrentSdk.getFilesOfTorrentByHash(hash: self.torrentHash),
                files.count == upd.count {
                for idx in 0 ..< files.count {
                    files[idx].update(with: upd[idx])
                }
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: TorrentFilesController.self.filesUpdatedNotification, object: nil)
            }
        }
    }
    
    @objc func updateUI() {
        fileProvider.update()
    }
    
    func setFilesPriority() {
        TorrentSdk.setTorrentFilesPriority(hash: torrentHash, states: files.map { $0.priority })
    }
    
    @IBAction func deselectAllAction(_ sender: Any) {
        fileProvider.deselectAll()
        setFilesPriority()
    }
    
    @IBAction func selectAllAction(_ sender: Any) {
        fileProvider.selectAll()
        setFilesPriority()
    }
    
    @IBAction func editAction(_ sender: Any) {}
}

extension TorrentFilesController: FileProviderDelegate {
    func fileSelected(file: FileModel) {
        setFilesPriority()
    }
    
    func folderSelected(folder: FolderModel) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "TorrentFilesController") as! TorrentFilesController
        vc.initialize(torrentHash: torrentHash, path: folder.path, files: files)
        show(vc, sender: self)
    }
    
    func folderPriorityChanged(folder: FolderModel) {
        setFilesPriority()
    }
    
    func fileActionCalled(file: FileModel) {
        setFilesPriority()
    }
}
