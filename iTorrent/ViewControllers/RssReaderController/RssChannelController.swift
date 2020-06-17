//
//  RssChannelController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 06.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit
import MarqueeLabel

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
        
        let button = UIBarButtonItem(image: UIImage(named: "Share"), style: .plain, target: self, action: #selector(openLink))
        navigationItem.setRightBarButton(button, animated: false)
        
        // MARQUEE LABEL
        let label = MarqueeLabel(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 44), duration: 8.0, fadeLength: 10)
        label.font = UIFont.boldSystemFont(ofSize: 17)
        label.textAlignment = NSTextAlignment.center
        label.textColor = Themes.current.mainText
        label.trailingBuffer = 44
        label.text = model.displayTitle
        navigationItem.titleView = label
    }
    
    @objc func openLink() {
        let dialog = ThemedUIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        dialog.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        
        let openInSafari = UIAlertAction(title: Localize.get("Open in Safari"), style: .default) { _ in
            UIApplication.shared.openURL(self.model.link)
        }
        let cancel = UIAlertAction(title: Localize.get("Cancel"), style: .cancel)
        
        dialog.addAction(openInSafari)
        dialog.addAction(cancel)
        
        present(dialog, animated: true)
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
        
        if !splitViewController!.isCollapsed {
            let navController = Utils.instantiateNavigationController()
            navController.viewControllers.append(vc)
            navController.isToolbarHidden = true
            splitViewController?.showDetailViewController(navController, sender: self)
        } else {
            splitViewController?.showDetailViewController(vc, sender: self)
        }
        
        setItem(at: indexPath, readed: true)
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let readed = model.items[indexPath.row].readed
        let title = readed ? Localize.get("RssChannelController.Unseen") : Localize.get("RssChannelController.Seen")
        let seen = UITableViewRowAction(style: .destructive, title: title) { (_, indexPath) in
            self.setItem(at: indexPath, readed: !readed)
        }
        return [seen]
    }
    
    func setItem(at indexPath: IndexPath, readed: Bool ) {
        self.model.items[indexPath.row].readed = readed
        self.model.items[indexPath.row].new = false
        (tableView.cellForRow(at: indexPath) as! RssItemCell).setModel(self.model.items[indexPath.row])
        RssFeedProvider.shared.rssModels.notifyUpdate()
    }
}
