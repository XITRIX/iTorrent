//
//  PreferencesProxyController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 20.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import ITorrentFramework
import UIKit

class ProxyPreferencesController: StaticTableViewController {
    override var tableAnimation: UITableView.RowAnimation { .fade }
    
    override var toolBarIsHidden: Bool? {
        true
    }
    
    deinit {
        print("PreferencesController Deinit")
    }

    override func initSections() {
        title = Localize.get("Settings.Network.Proxy")
        
        var proxyType = [CellModelProtocol]()
        proxyType.append(ButtonCell.Model(title: "Settings.Network.Proxy.Type", buttonTitleFunc: { UserPreferences.proxyType.title }) { [weak self] _ in
            guard let self = self else { return }
            
            let alert = ThemedUIAlertController(title: "\(Localize.get("Settings.Network.Proxy.SelectType")) \(UserPreferences.proxyType.title)", message: nil, preferredStyle: .actionSheet)
            alert.popoverPresentationController?.permittedArrowDirections = []
            alert.popoverPresentationController?.sourceView = self.view
            alert.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            
            ProxyType.allCases.forEach { type in
                if UserPreferences.proxyType == type { return }
                let action = UIAlertAction(title: type.title, style: .default) { _ in
                    UserPreferences.proxyType = type
                    self.updateData()
                }
                alert.addAction(action)
            }
            let cancel = UIAlertAction(title: Localize.get("Cancel"), style: .cancel)
            alert.addAction(cancel)
            
            self.present(alert, animated: true)
        })
        proxyType.append(TextFieldCell.Model(title: "Settings.Network.Proxy.Hostname", defaultValue: { UserPreferences.proxyHostname }, hiddenCondition: { UserPreferences.proxyType == ProxyType.none }, textEditAction: { text in
            UserPreferences.proxyHostname = text
        }))
        proxyType.append(TextFieldCell.Model(title: "Settings.Network.Proxy.Port", defaultValue: { "\(UserPreferences.proxyPort)" }, keyboardType: .numberPad, hiddenCondition: { UserPreferences.proxyType == ProxyType.none }, textEditAction: { text in
            if let port = Int(text) {
                UserPreferences.proxyPort = port
            }
        }))
        data.append(Section(rowModels: proxyType, header: "Settings.Network.Proxy.Type.Header"))
//        proxy.append(SwitchCell.Model(title: "Peer connection", defaultValue: { UserPreferences.proxyPeerConnections }, hint: "", hiddenCondition: { UserPreferences.proxyType == ProxyType.none }) { switcher in
//            UserPreferences.proxyPeerConnections = switcher.isOn
//        })
        var proxyAuth = [CellModelProtocol]()
        proxyAuth.append(SwitchCell.Model(title: "Settings.Network.Proxy.Auth", defaultValue: { UserPreferences.proxyRequiresAuth }, hiddenCondition: { UserPreferences.proxyType == ProxyType.none }) { [weak self] switcher in
            UserPreferences.proxyRequiresAuth = switcher.isOn
            self?.updateData()
        })
        proxyAuth.append(TextFieldCell.Model(title: "Settings.Network.Proxy.Login", defaultValue: { UserPreferences.proxyUsername }, hiddenCondition: { UserPreferences.proxyType == ProxyType.none || !UserPreferences.proxyRequiresAuth }, textEditAction: { text in
            UserPreferences.proxyUsername = text
        }))
        proxyAuth.append(TextFieldCell.Model(title: "Settings.Network.Proxy.Password", defaultValue: { UserPreferences.proxyPassword }, isPassword: true, hiddenCondition: { UserPreferences.proxyType == ProxyType.none || !UserPreferences.proxyRequiresAuth }, textEditAction: { text in
            UserPreferences.proxyPassword = text
        }))
        data.append(Section(rowModels: proxyAuth, header: "Settings.Network.Proxy.Auth.Header"))
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        TorrentSdk.applySettingsPack(settingsPack: SettingsPack.userPrefered)
    }
}
