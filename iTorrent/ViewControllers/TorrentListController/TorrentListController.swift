//
//  TorrentsListController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 02.04.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import GoogleMobileAds
import UIKit

class TorrentListController: MvvmViewController<TorrentListViewModel> {
    @IBOutlet var tableView: ThemedUITableView!
    @IBOutlet var adsView: GADBannerView!
    
    @IBOutlet var tableviewPlaceholder: UIView!
    @IBOutlet var tableviewPlaceholderImage: UIImageView!
    @IBOutlet var tableviewPlaceholderText: UILabel!
    
    @IBOutlet var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet var rssButton: UIBarButtonItem!
    
    var initialBarButtonItems: [UIBarButtonItem] = []
    var editmodeBarButtonItems: [UIBarButtonItem] = []
    
    var searchController: UISearchController = UISearchController(searchResultsController: nil)
    var adsLoaded = false
    
    var torrentListDataSource: TorrentListDataSource!
    
    override var toolBarIsHidden: Bool? {
        return false
    }
    
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
    
    override func setupViews() {
        localize()
        
        initializeTableView()
        initializeAds()
        initializeSearchView()
        initializeEditMode()
        showUpdateLog()
    }
    
    override func binding() {
        /// TableView Binding
        viewModel.tableViewData.bind { torrents in
            var snapshot = DataSnapshot<String, TorrentModel>()
            snapshot.appendSections(torrents.map { $0.title })
            torrents.forEach { snapshot.appendItems($0.items, toSection: $0.title) }
            self.torrentListDataSource.apply(snapshot)
            self.tableView.visibleCells.forEach { ($0 as! UpdatableModel).updateModel() }
        }.dispose(with: disposalBag)
        
        /// Binding Loading Indicator
//        loadingIndicator.isAnimatingBox.bindTo(viewModel.loadingIndicatiorHidden).dispose(with: disposalBag)
        viewModel.loadingIndicatiorHidden.bind { [weak self] hidden in
            if hidden {
                self?.loadingIndicator.stopAnimating()
            } else {
                self?.loadingIndicator.startAnimating()
            }
        }.dispose(with: disposalBag)
        
        /// Binding RSS Indicator
        RssFeedProvider.shared.isRssUpdates.bind { [weak self] updates in
            self?.rssButton.image = UIImage(named: updates ? "RssNews" : "Rss")
        }.dispose(with: disposalBag)
        
        /// Binding TableView Placeholder
//        tableviewPlaceholder.isHiddenBox.bindTo(viewModel.tableviewPlaceholderHidden).dispose(with: disposalBag)
        viewModel.tableviewPlaceholderHidden.bind { [weak self] hidden in
            self?.tableviewPlaceholder.isHidden = hidden
        }.dispose(with: disposalBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        smoothlyDeselectRows(in: tableView)
        viewWillAppearAds()
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
    
    @IBAction func rssAction(_ sender: UIBarButtonItem) {
        let back = UIBarButtonItem()
        back.title = title
        navigationItem.backBarButtonItem = back
        show(RssFeedController(), sender: self)
    }
    
    @IBAction func sortAction(_ sender: UIBarButtonItem) {
        let sortingController = SortingManager.createSortingController(buttonItem: sender, applyChanges: {
            self.viewModel.update()
            self.updateScrollInset()
        })
        present(sortingController, animated: true)
    }
}
 
