//
//  NetworkPreferencesController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 19.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import ITorrentFramework
import UIKit

class NetworkPreferencesController: StaticTableViewController {
    
    override var toolBarIsHidden: Bool? {
        true
    }

    deinit {
        print("PreferencesController Deinit")
    }

    override func initSections() {
        title = Localize.get("Settings.Network.Header")
        
        weak var weakSelf = self

        var network = [CellModelProtocol]()
        network.append(SwitchCell.Model(title: "Settings.Network.DHT", defaultValue: { UserPreferences.enableDht }, hint: "Settings.Network.DHT.Hint") { switcher in
            UserPreferences.enableDht = switcher.isOn
            TorrentSdk.applySettingsPack(settingsPack: SettingsPack.userPrefered)
        })
        network.append(SwitchCell.Model(title: "Settings.Network.LSD", defaultValue: { UserPreferences.enableLsd }, hint: "Settings.Network.LSD.Hint") { switcher in
            UserPreferences.enableLsd = switcher.isOn
            TorrentSdk.applySettingsPack(settingsPack: SettingsPack.userPrefered)
        })
        network.append(SwitchCell.Model(title: "Settings.Network.uTP", defaultValue: { UserPreferences.enableUtp }, hint: "Settings.Network.uTP.Hint") { switcher in
            UserPreferences.enableUtp = switcher.isOn
            TorrentSdk.applySettingsPack(settingsPack: SettingsPack.userPrefered)
        })
        network.append(SwitchCell.Model(title: "Settings.Network.UPnP", defaultValue: { UserPreferences.enableUpnp }) { switcher in
            UserPreferences.enableUpnp = switcher.isOn
            TorrentSdk.applySettingsPack(settingsPack: SettingsPack.userPrefered)
        })
        network.append(SwitchCell.Model(title: "Settings.Network.NAT-PMP", defaultValue: { UserPreferences.enableNatpmp }) { switcher in
            UserPreferences.enableNatpmp = switcher.isOn
            TorrentSdk.applySettingsPack(settingsPack: SettingsPack.userPrefered)
        })
        data.append(Section(rowModels: network, header: "Settings.Network.Protocols"))
        
        var port = [CellModelProtocol]()
        port.append(SwitchCell.Model(title: "Settings.Network.DefauldPort", defaultValue: { UserPreferences.defaultPort }, hint: "Settings.Network.DefauldPort.Hint") { switcher in
            UserPreferences.defaultPort = switcher.isOn
            TorrentSdk.applySettingsPack(settingsPack: SettingsPack.userPrefered)
            weakSelf?.updateData()
        })
        port.append(TextFieldCell.Model(title: "Settings.Network.PortFirst", placeholder: "6881", defaultValue: { String(UserPreferences.portRangeFirst) }, keyboardType: .numberPad, hiddenCondition: { UserPreferences.defaultPort }) { port in
            var iPort: Int
            if let port = Int(port) {
                iPort = port
            } else {
                iPort = 6881
            }
            
            UserPreferences.portRangeFirst = iPort

            if UserPreferences.portRangeSecond - iPort < 0 {
                UserPreferences.portRangeSecond = iPort + 10
            }

            weakSelf?.updateData()
            TorrentSdk.applySettingsPack(settingsPack: SettingsPack.userPrefered)
        })
        port.append(TextFieldCell.Model(title: "Settings.Network.PortSecond", placeholder: "6891", defaultValue: { String(UserPreferences.portRangeSecond) }, keyboardType: .numberPad, hiddenCondition: { UserPreferences.defaultPort }) { port in
            var iPort: Int
            if let port = Int(port) {
                iPort = port
            } else {
                iPort = UserPreferences.portRangeFirst + 10
            }
            
            if iPort - UserPreferences.portRangeFirst < 0 {
                iPort = UserPreferences.portRangeFirst + 10
            }
            
            UserPreferences.portRangeSecond = iPort

            weakSelf?.updateData()
            TorrentSdk.applySettingsPack(settingsPack: SettingsPack.userPrefered)
        })
        data.append(Section(rowModels: port, header: "Settings.Network.Port"))
    }
}
