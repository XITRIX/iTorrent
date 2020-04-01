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
    
    var torrentSections: [ReloadableSection<TorrentModel>] = []
    
    func localize() {
        tableviewPlaceholderText.text = Localize.get("MainController.Table.Placeholder.Text")
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
    
    @objc func update(animated: Bool = true) {
        if Core.shared.state == .Initializing { return }
        else { loadingIndicator.stopAnimating() }
        
        DispatchQueue.global(qos: .userInteractive).async {
            let searchFiltered = Array(Core.shared.torrents.values).filter { self.searchFilter($0) }
            let tempBuf = SortingManager.sortTorrentManagers(managers: searchFiltered)
            let changes = DiffCalculator.calculate(oldSectionItems: self.torrentSections, newSectionItems: tempBuf)
            self.torrentSections = tempBuf
            DispatchQueue.main.async {
                if changes.hasChanges() {
                    let animation: UITableView.RowAnimation = animated ? .fade : .none
                    
                    self.tableView.beginUpdates()
                    if changes.deletes.count > 0 { self.tableView.deleteSections(changes.deletes, with: animation) }
                    if changes.inserts.count > 0 { self.tableView.insertSections(changes.inserts, with: animation) }
                    if changes.updates.reloads.count > 0 { self.tableView.reloadRows(at: changes.updates.reloads, with: animation) }
                    if changes.updates.inserts.count > 0 { self.tableView.insertRows(at: changes.updates.inserts, with: animation) }
                    if changes.updates.deletes.count > 0 { self.tableView.deleteRows(at: changes.updates.deletes, with: animation) }
                    if changes.updates.moves.count > 0 { changes.updates.moves.forEach { self.tableView.moveRow(at: $0.from, to: $0.to) } }
                    if changes.moves.count > 0 { changes.moves.forEach { self.tableView.moveSection($0.from, toSection: $0.to) } }
                    self.tableView.endUpdates()
                }
                
                self.tableView.visibleCells.forEach { ($0 as! UpdatableModel).updateModel() }
                
                self.tableviewPlaceholder.isHidden = self.torrentSections.contains(where: { $0.value.count > 0 })
            }
        }
    }
    
    @IBAction func addTorrentAction(_ sender: UIBarButtonItem) {
        addTorrent(sender)
    }
    
    @IBAction func editAction(_ sender: UIBarButtonItem) {
        triggerEditMode()
    }
    
    @IBAction func preferencesAction(_ sender: UIBarButtonItem) {
        show(PreferencesController(), sender: self)
    }
    
    @IBAction func sortAction(_ sender: UIBarButtonItem) {
        let sortingController = SortingManager.createSortingController(buttonItem: sender, applyChanges: {
            self.update()
        })
        present(sortingController, animated: true)
    }
}
