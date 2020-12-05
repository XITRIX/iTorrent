//
//  RssChannelSetup.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 11.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

class RssChannelSetupController: ThemedUITableViewController {
    @IBOutlet var titleText: ThemedUILabel!
    @IBOutlet var descriptionText: ThemedUILabel!
    @IBOutlet var notifyText: ThemedUILabel!
    
    @IBOutlet var urlLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var descriptionLabel: ThemedUILabel!
    @IBOutlet var notificationSwitch: UISwitch!
    
    var model: RssModel!
    
    func localize() {
        titleText.text = Localize.get("RssChannelSetup.Title")
        descriptionText.text = Localize.get("RssChannelSetup.Description")
        notifyText.text = Localize.get("RssChannelSetup.Notify")
    }
    
    override func themeUpdate() {
        super.themeUpdate()
        view.backgroundColor = .clear
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        localize()
        
        urlLabel.text = model.xmlLink.absoluteString
        
        model.customTitle.observeNext(with: { _ in
            self.titleLabel.text = self.model.displayTitle
        }).dispose(in: bag)
        
        model.customDescriotion.observeNext(with: { _ in
            self.descriptionLabel.text = self.model.displayDescription
        }).dispose(in: bag)
        
        notificationSwitch.setOn(!model.muteNotifications.value, animated: false)
        notificationSwitch.reactive.isOn.observeNext { on in
            self.model.muteNotifications.value = !on
            RssFeedProvider.shared.rssModels.notifyUpdate() 
        }.dispose(in: bag)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            UIPasteboard.general.string = model.xmlLink.absoluteString
            Dialog.withTimer(self, title: Localize.get("RssChannelSetup.UrlCopied"))
        case 1:
            Dialog.withTextField(self, title: Localize.get("RssChannelSetup.Title"), textFieldConfiguration: { textField in
                textField.placeholder = self.model.title
                textField.text = self.model.customTitle.value
            }) { textField in
                self.model.customTitle.value = textField.text
                self.titleLabel.text = self.model.displayTitle
                RssFeedProvider.shared.rssModels.notifyUpdate()
            }
        case 2:
            Dialog.withTextField(self, title: Localize.get("RssChannelSetup.Description"), textFieldConfiguration: { textField in
                textField.placeholder = self.model.description
                textField.text = self.model.customDescriotion.value
            }) { textField in
                self.model.customDescriotion.value = textField.text
                self.descriptionLabel.text = self.model.displayDescription
                RssFeedProvider.shared.rssModels.notifyUpdate()
            }
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
