//
//  RssChannelController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 06.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import MarqueeLabel
import UIKit

class RssChannelController: ThemedUITableViewController {
    override var toolBarIsHidden: Bool? {
        true
    }
    
    var model: RssModel!
    
    func setModel(_ model: RssModel) {
        self.model = model
    }
    
    override func themeUpdate() {
        super.themeUpdate()
        let theme = Themes.current
        view.backgroundColor = theme.backgroundMain
        
        if let label = navigationItem.titleView as? UILabel {
            let theme = Themes.current
            label.textColor = theme.mainText
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = model.title
        tableView.register(RssItemCell.nib, forCellReuseIdentifier: RssItemCell.id)
        
        if #available(iOS 14.0, *) {
            let button = UIBarButtonItem(title: nil, image: #imageLiteral(resourceName: "More2"), primaryAction: nil, menu: createMenu())
            navigationItem.setRightBarButton(button, animated: false)
        } else {
            let button = UIBarButtonItem(image: #imageLiteral(resourceName: "More2"), style: .plain, target: self, action: #selector(openLink))
            navigationItem.setRightBarButton(button, animated: false)
        }
        
        // MARQUEE LABEL
        let label = MarqueeLabel(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 44), duration: 8.0, fadeLength: 10)
        label.font = UIFont.boldSystemFont(ofSize: 17)
        label.textAlignment = NSTextAlignment.center
        label.textColor = Themes.current.mainText
        label.trailingBuffer = 44
        model.customTitle.observeNext(with: { _ in
            label.text = self.model.displayTitle
        }).dispose(in: bag)
        navigationItem.titleView = label
    }
    
    @available(iOS 13.0, *)
    func createMenu() -> UIMenu {
        var actions = [
            UIAction(title: "RssChannelController.ReadAll".localized, image: UIImage(systemName: "checkmark.circle"), handler: { _ in self.readAll() })
        ]
        if let link = self.model.link {
            actions.append(UIAction(title: "Open in Safari".localized, image: UIImage(systemName: "safari"), handler: { _ in UIApplication.shared.openURL(link) }))
        }
        return UIMenu(children: actions)
    }
    
    @objc func openLink() {
        let dialog = ThemedUIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        dialog.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        
        let readAll = UIAlertAction(title: "RssChannelController.ReadAll".localized, style: .default) { _ in
            self.readAll()
        }
        let openInSafari = UIAlertAction(title: "Open in Safari".localized, style: .default) { _ in
            if let link = self.model.link {
                UIApplication.shared.openURL(link)
            }
        }
        let cancel = UIAlertAction(title: "Cancel".localized, style: .cancel)
        
        dialog.addAction(readAll)
        if self.model.link != nil {
            dialog.addAction(openInSafari)
        }
        dialog.addAction(cancel)
        
        present(dialog, animated: true)
    }
    
    func readAll() {
        for i in 0 ..< model.items.count {
            model.items[i].readed = true
            model.items[i].new = false
            
            let indexPath = IndexPath(row: i, section: 0)
            (tableView.cellForRow(at: indexPath) as! RssItemCell).setModel(model.items[i])
        }
    }
}

extension RssChannelController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        model.items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RssItemCell.id, for: indexPath) as! RssItemCell
        cell.setModel(model.items[indexPath.row])
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = RssItemController()
        vc.setModel(model.items[indexPath.row])
        
        if let splitViewController = splitViewController {
            if !splitViewController.isCollapsed {
                let navController = Utils.instantiateNavigationController()
                navController.viewControllers.append(vc)
                navController.isToolbarHidden = true
                splitViewController.showDetailViewController(navController, sender: self)
            } else {
                splitViewController.showDetailViewController(vc, sender: self)
            }
        } else {
            show(vc, sender: self)
        }
        
        setItem(at: indexPath, readed: true)
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let readed = model.items[indexPath.row].readed
        let title = readed ? Localize.get("RssChannelController.Unseen") : Localize.get("RssChannelController.Seen")
        let seen = UITableViewRowAction(style: .destructive, title: title) { _, indexPath in
            self.setItem(at: indexPath, readed: !readed)
        }
        return [seen]
    }
    
    func setItem(at indexPath: IndexPath, readed: Bool) {
        model.items[indexPath.row].readed = readed
        model.items[indexPath.row].new = false
        (tableView.cellForRow(at: indexPath) as! RssItemCell).setModel(model.items[indexPath.row])
        RssFeedProvider.shared.rssModels.notifyUpdate()
    }
}
