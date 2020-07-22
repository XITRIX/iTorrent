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
        notifyText.text = Localize.get("RssChannelSetup.Description")
    }
    
    override func themeUpdate() {
        super.themeUpdate()
        view.backgroundColor = .clear
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        urlLabel.text = model.xmlLink.absoluteString
        titleLabel.text = model.displayTitle
        descriptionLabel.text = model.displayDescription
        notificationSwitch.setOn(!model.muteNotifications, animated: false)
    }
    
    @IBAction func notificationAction(_ sender: UISwitch) {
        model.muteNotifications = !sender.isOn
        RssFeedProvider.shared.rssModels.notifyUpdate()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            UIPasteboard.general.string = model.xmlLink.absoluteString
            Dialog.withTimer(self, title: "RssChannelSetup.UrlCopied")
        case 1:
            Dialog.withTextField(self, title: "RssChannelSetup.Title", textFieldConfiguration: { textField in
                textField.placeholder = self.model.title
                textField.text = self.model.customTitle
            }) { textField in
                self.model.customTitle = textField.text
                self.titleLabel.text = self.model.displayTitle
                RssFeedProvider.shared.rssModels.notifyUpdate()
            }
        case 2:
            Dialog.withTextField(self, title: "RssChannelSetup.Description", textFieldConfiguration: { textField in
                textField.placeholder = self.model.description
                textField.text = self.model.customDescriotion
            }) { textField in
                self.model.customDescriotion = textField.text
                self.titleLabel.text = self.model.displayDescription
                RssFeedProvider.shared.rssModels.notifyUpdate()
            }
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
