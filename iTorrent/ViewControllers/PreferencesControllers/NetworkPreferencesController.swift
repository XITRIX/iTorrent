//
//  NetworkPreferencesController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 19.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

class NetworkPreferencesController: StaticTableViewController {
    override var toolBarIsHidden: Bool? {
        true
    }

    override func initSections() {
        title = Localize.get("Settings.Network.Header")

        var network = [CellModelProtocol]()
        network.append(SwitchCell.Model(title: "Settings.Network.DHT", defaultValue: { UserPreferences.enableDht }, hint: "Settings.Network.DHT.Hint") { switcher in
            UserPreferences.enableDht = switcher.isOn
            TorrentSdk.applySettingsPack()
        })
        network.append(SwitchCell.Model(title: "Settings.Network.LSD", defaultValue: { UserPreferences.enableLsd }, hint: "Settings.Network.LSD.Hint") { switcher in
            UserPreferences.enableLsd = switcher.isOn
            TorrentSdk.applySettingsPack()
        })
        network.append(SwitchCell.Model(title: "Settings.Network.uTP", defaultValue: { UserPreferences.enableUtp }, hint: "Settings.Network.uTP.Hint") { switcher in
            UserPreferences.enableUtp = switcher.isOn
            TorrentSdk.applySettingsPack()
        })
        network.append(SwitchCell.Model(title: "Settings.Network.UPnP", defaultValue: { UserPreferences.enableUpnp }) { switcher in
            UserPreferences.enableUpnp = switcher.isOn
            TorrentSdk.applySettingsPack()
        })
        network.append(SwitchCell.Model(title: "Settings.Network.NAT-PMP", defaultValue: { UserPreferences.enableNatpmp }) { switcher in
            UserPreferences.enableNatpmp = switcher.isOn
            TorrentSdk.applySettingsPack()
        })
        data.append(Section(rowModels: network, header: "Settings.Network.Protocols"))
    }
}
