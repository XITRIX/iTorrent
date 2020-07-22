//
//  RssFeedController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 06.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import DeepDiff
import UIKit

class RssFeedController: ThemedUIViewController {
    var tableView: UITableView!
    var placeholder: PlaceHolderView!
    var refreshControl: UIRefreshControl?
    
    var editButton: UIBarButtonItem {
        let title = isEditing ? Localize.get("Done") : Localize.get("Edit")
        let style: UIBarButtonItem.Style = isEditing ? .done : .plain
        return UIBarButtonItem(title: title, style: style, target: self, action: #selector(editMode))
    }
    
    lazy var addFeedButton: UIBarButtonItem = {
        UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addRss))
    }()
    
    lazy var removeFeedButton: UIBarButtonItem = {
        UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(removeRss))
    }()
    
    let disposalBag = DisposalBag()
    
    var dataSource: RssFeedDataSource!
    
    var channelSetupView: PopupView?
    
    override var toolBarIsHidden: Bool? {
        !isEditing || channelSetupView != nil
    }
    
    override func themeUpdate() {
        super.themeUpdate()
        let theme = Themes.current
        view.backgroundColor = theme.backgroundMain
    }
    
    override func loadView() {
        super.loadView()
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        
        title = "RSS"
        navigationItem.setRightBarButton(editButton, animated: false)
        
        tableView = ThemedUITableView(frame: view.frame)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(tableView)
        
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbarItems = [space, addFeedButton, space, removeFeedButton, space]
        
        placeholder = PlaceHolderView.fromNib()
        placeholder.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        placeholder.frame = view.frame
        view.addSubview(placeholder)
        
        placeholder.textLabel.text = "RssFeedProvider.Empty.Text".localized
        placeholder.imageView.image = UIImage(named: "EmptyRss")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = RssFeedDataSource(tableView: tableView, cellProvider: { (tableView, indexPath, model) -> UITableViewCell in
            self.editModeUpdate()
            let cell = tableView.dequeueReusableCell(withIdentifier: RssChannelCell.id, for: indexPath) as! RssChannelCell
            cell.setModel(model)
            cell.parent = self
            return cell
        })
        
        refreshControl = UIRefreshControl()
        refreshControl?.backgroundColor = .clear
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
        
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else if let refreshControl = refreshControl {
            tableView.addSubview(refreshControl)
        }
        
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.register(RssChannelCell.nib, forCellReuseIdentifier: RssChannelCell.id)
        tableView.rowHeight = 59
        tableView.delegate = self
        tableView.dataSource = dataSource
        
        RssFeedProvider.shared.rssModels.bind { [weak self] new in
            guard let self = self else { return }
            
            self.placeholder.isHidden = new.count != 0
            
            var snapshot = DataSnapshot<String, RssModel>()
            snapshot.appendSections([""])
            snapshot.appendItems(new, toSection: "")
            self.dataSource.apply(snapshot, animateInitial: false) {
                self.editModeUpdate()
                self.tableView.visibleCells.forEach { ($0 as! RssChannelCell).updateCellView() }
            }
        }.dispose(with: disposalBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        smoothlyDeselectRows(in: tableView)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }
    
    @objc func refresh() {
        RssFeedProvider.shared.fetchUpdates { _ in
            self.refreshControl?.endRefreshing()
        }
    }
    
    @objc func editMode() {
        setEditing(!isEditing, animated: true)
        navigationController?.setToolbarHidden(toolBarIsHidden!, animated: true)
        channelSetupView?.dismiss()
        editModeUpdate()
        UIView.animate(withDuration: 0.3) {
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func addRss() {
        Dialog.withTextField(self,
                             title: "RssFeedController.AddTitle",
                             textFieldConfiguration: { textField in
                                 textField.placeholder = "https://"
                                 
                                 if #available(iOS 10.0, *),
                                     UIPasteboard.general.hasStrings,
                                     let text = UIPasteboard.general.string,
                                     text.starts(with: "https://") ||
                                     text.starts(with: "http://") {
                                     textField.text = UIPasteboard.general.string
                                 }
        }, okText: "Add") { textField in
            RssFeedProvider.shared.addFeed(textField.text!) { result in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    Dialog.show(self, title: "Error", message: error.localizedDescription)
                }
            }
        }
    }
    
    @objc func removeRss() {
        guard let selected = tableView.indexPathsForSelectedRows else { return }
        
        let message = selected.compactMap { dataSource.snapshot?.getItem(from: $0)?.title }.joined(separator: "\n")
        let urls = selected.compactMap { dataSource.snapshot?.getItem(from: $0)?.link }
        let alert = ThemedUIAlertController(title: Localize.get("RssFeedController.RemoveTitle"), message: message, preferredStyle: .alert)
        
        let delete = UIAlertAction(title: Localize.get("Remove"), style: .destructive) { _ in
            RssFeedProvider.shared.removeFeeds(urls)
        }
        let cancel = UIAlertAction(title: Localize.get("Cancel"), style: .cancel)
        
        alert.addAction(delete)
        alert.addAction(cancel)
        
        present(alert, animated: true)
    }
    
    func editModeUpdate() {
        navigationItem.setRightBarButton(editButton, animated: false)
        removeFeedButton.isEnabled = isEditing && tableView.indexPathsForSelectedRows?.count ?? 0 > 0
        
//        if isEditing {
//            navigationItem.setLeftBarButton(UIBarButtonItem(title: nil, style: .plain, target: self, action: nil), animated: true)
//        } else {
//            navigationItem.setLeftBarButton(nil, animated: true)
//        }
    }
}

extension RssFeedController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isEditing {
            editModeUpdate()
        } else {
            let vc = RssChannelController()
            vc.setModel(dataSource.snapshot!.getItem(from: indexPath)!)
            show(vc, sender: self)
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if isEditing {
            editModeUpdate()
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .none
    }
}

class RssFeedDataSource: DiffableDataSource<String, RssModel> {
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        tableView.isEditing
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        true
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        super.tableView(tableView, moveRowAt: sourceIndexPath, to: destinationIndexPath)
        RssFeedProvider.shared.rssModels.updateWithoutNotify {
            let itemToMove = RssFeedProvider.shared.rssModels.variable.remove(at: sourceIndexPath.row)
            RssFeedProvider.shared.rssModels.variable.insert(itemToMove, at: destinationIndexPath.row)
        }
    }
}
