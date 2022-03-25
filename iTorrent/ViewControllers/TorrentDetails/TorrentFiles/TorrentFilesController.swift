//
//  TorrentFilesController.swift
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

import UIKit

class TorrentFilesController: ThemedUIViewController {
    private var canUpdateData = true
    
    static let filesUpdatedNotification = NSNotification.Name(rawValue: "filesUpdatedNotification")
    
    var editButton: UIBarButtonItem!
    var doneButton: UIBarButtonItem!
    
    var selectAllButton: UIBarButtonItem!
    var deselectAllButton: UIBarButtonItem!
    
    lazy var toolBarItems: [UIBarButtonItem] = {
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        return [deselectAllButton, space, selectAllButton]
    }()
    
    var priorityButton: UIBarButtonItem!
    var shareButton: UIBarButtonItem!
    
    lazy var editToolBarItems: [UIBarButtonItem] = {
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        return [priorityButton, space, shareButton]
    }()
    
    var tableView: ThemedUITableView!
    
    var torrentHash: String = ""
    var fileProvider: FileProviderTableDataSource!
    var files: [FileModel]!
    var path: URL!
    
    init(hash: String, path: URL = URL(string: "/")!, files: [FileModel]! = nil) {
        super.init()
        self.torrentHash = hash
        self.files = files
        self.path = path
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func themeUpdate() {
        super.themeUpdate()
        tableView.backgroundColor = Themes.current.backgroundMain
    }
    
    override func loadView() {
        super.loadView()
        
        tableView = ThemedUITableView(frame: view.bounds)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(tableView)
        
        editButton = UIBarButtonItem(image: #imageLiteral(resourceName: "More2"), style: .plain, target: self, action: #selector(editAction))
        doneButton = UIBarButtonItem(title: "Done".localized, style: .done, target: self, action: #selector(editAction))
        selectAllButton = UIBarButtonItem(title: "TorrentFilesController.SelectAll".localized, style: .plain, target: self, action: #selector(selectAllAction))
        selectAllButton.tintColor = .systemBlue
        deselectAllButton = UIBarButtonItem(title: "TorrentFilesController.DeselectAll".localized, style: .plain, target: self, action: #selector(deselectAllAction))
        deselectAllButton.tintColor = .systemRed
        
        priorityButton = UIBarButtonItem(image: #imageLiteral(resourceName: "Order"), style: .plain, target: self, action: #selector(editAction))
        shareButton = UIBarButtonItem(image: #imageLiteral(resourceName: "Share"), style: .plain, target: self, action: #selector(editAction))
        
        navigationItem.setRightBarButton(editButton, animated: false)
        toolbarItems = toolBarItems
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        tableView.allowsSelection = true
        tableView.allowsSelectionDuringEditing = true
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.dataSource = fileProvider
        tableView.delegate = fileProvider
        
        observableIsEditing.observeNext { [unowned self] editing in
//            editButton.style = editing ? .done : .plain
//            editButton.title = editing ? "Done".localized : "Select".localized
            navigationItem.setRightBarButton(editing ? doneButton : editButton, animated: true)
            
            setToolbarItems(editing ? editToolBarItems : toolBarItems, animated: true)
        }.dispose(in: bag)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(updateUI), name: TorrentFilesController.filesUpdatedNotification, object: nil)
    }
    
    @objc func updateData() {
        guard canUpdateData else { return }
        canUpdateData = false
        DispatchQueue.global(qos: .utility).async { [files] in
            guard let files = files else { return }
            if let upd = TorrentSdk.getFilesOfTorrentByHash(hash: self.torrentHash),
               files.count == upd.count
            {
                for idx in 0 ..< files.count {
                    files[idx].update(with: upd[idx])
                }
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: TorrentFilesController.filesUpdatedNotification, object: nil)
            }
            self.canUpdateData = true
        }
    }
    
    @objc func updateUI() {
        fileProvider.update()
    }
    
    func setFilesPriority() {
        TorrentSdk.setTorrentFilesPriority(hash: torrentHash, states: files.map { $0.priority })
    }
    
    @objc func deselectAllAction() {
        fileProvider.deselectAll()
        setFilesPriority()
    }
    
    @objc func selectAllAction() {
        fileProvider.selectAll()
        setFilesPriority()
    }
    
    @objc func editAction() {
        let editing = !isEditing
        setEditing(editing, animated: true)
        tableView.setEditing(editing, animated: true)
    }
}

extension TorrentFilesController: FileProviderDelegate {
    func fileSelected(file: FileModel) {
        setFilesPriority()
    }
    
    func folderSelected(folder: FolderModel) {
        let vc = TorrentFilesController(hash: torrentHash, path: folder.path, files: files)
        show(vc, sender: self)
    }
    
    func folderPriorityChanged(folder: FolderModel) {
        setFilesPriority()
    }
    
    func fileActionCalled(file: FileModel) {
        setFilesPriority()
    }
}
