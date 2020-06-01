//
//  TorrentsListController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 02.04.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import GoogleMobileAds
import UIKit

class TorrentListController: ThemedUIViewController {
    @IBOutlet var tableView: ThemedUITableView!
    @IBOutlet var adsView: GADBannerView!
    
    @IBOutlet var tableviewPlaceholder: UIView!
    @IBOutlet var tableviewPlaceholderImage: UIImageView!
    @IBOutlet var tableviewPlaceholderText: UILabel!
    
    @IBOutlet var loadingIndicator: UIActivityIndicatorView!
    
    var initialBarButtonItems: [UIBarButtonItem] = []
    var editmodeBarButtonItems: [UIBarButtonItem] = []
    
    var searchController: UISearchController = UISearchController(searchResultsController: nil)
    var searchFilter: String?
    
    var adsLoaded = false
    
    var torrentListDataSource: TorrentListDataSource!
    
    func localize() {
        tableviewPlaceholderText.text = Localize.get("MainController.Table.Placeholder.Text")
    }
    
    func showUpdateLog() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
            if let updateDialog = Dialog.createUpdateLogs(finishAction: {
                if let newsDialog = Dialog.createNewsAlert() {
                    self.present(newsDialog, animated: true)
                }
            }) {
                self.present(updateDialog, animated: true)
            }
        }
    }
    
    override func themeUpdate() {
        super.themeUpdate()
        
        let theme = Themes.current
        view.backgroundColor = theme.backgroundMain
        tableView.backgroundColor = theme.backgroundMain
        tableviewPlaceholderImage.tintColor = theme.secondaryText
        searchbarUpdateTheme(theme)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        localize()
        
        initializeTableView()
        initializeAds()
        initializeSearchView()
        initializeEditMode()
        showUpdateLog()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(update), name: .mainLoopTick, object: nil)
        navigationController?.isToolbarHidden = false
        smoothlyDeselectRows(in: tableView)
        viewWillAppearAds()
        update()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    let updateSemaphore = DispatchSemaphore(value: 1)
    @objc func update(animated: Bool = true) {
        if Core.shared.state == .Initializing { return }
        else { loadingIndicator.stopAnimating() }
        
        let searchFiltered = Array(Core.shared.torrents.values).filter { self.searchFilter($0) }
        let tempBuf = SortingManager.sort(managers: searchFiltered)
        
        var snapshot = DataSnapshot<String, TorrentModel>()
        snapshot.appendSections(tempBuf.map{$0.title})
        tempBuf.enumerated().forEach { snapshot.appendItems($0.element.items, toSection: $0.element.title) }
        
        self.torrentListDataSource.apply(snapshot)

        self.tableView.visibleCells.forEach { ($0 as! UpdatableModel).updateModel() }
        self.tableviewPlaceholder.isHidden = tempBuf.contains(where: { $0.items.count > 0 })
    }
    
    @IBAction func addTorrentAction(_ sender: UIBarButtonItem) {
        addTorrent(sender)
    }
    
    @IBAction func editAction(_ sender: UIBarButtonItem) {
        triggerEditMode()
    }
    
    @IBAction func preferencesAction(_ sender: UIBarButtonItem) {
        let back = UIBarButtonItem()
        back.title = title
        navigationItem.backBarButtonItem = back
        show(PreferencesController(), sender: self)
    }
    
    @IBAction func sortAction(_ sender: UIBarButtonItem) {
        let sortingController = SortingManager.createSortingController(buttonItem: sender, applyChanges: {
            self.update()
        })
        present(sortingController, animated: true)
    }
}
