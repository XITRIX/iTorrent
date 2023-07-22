//
//  NetworkPreferencesController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 19.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

#if TRANSMISSION
import ITorrentTransmissionFramework
#else
import ITorrentFramework
#endif

import UIKit

class NetworkPreferencesController: StaticTableViewController {
    
    override var toolBarIsHidden: Bool? {
        true
    }

    deinit {
        print("PreferencesController Deinit")
    }

    override func initSections() {
        title = Localize.get("Settings.Network.Connection")

        weak var weakSelf = self

        // MARK: - Encryption
        var encryption = [CellModelProtocol]()
        encryption.append(ButtonCell.Model(title: "Settings.Network.Encryption.Title", hint: "Settings.Network.Encryption.Hint", buttonTitleFunc: { UserPreferences.encryptionPolicy.name }, action: { button in
            let alert = ThemedUIAlertController(title: "Settings.Network.Encryption.Select".localized, message: nil, preferredStyle: .actionSheet)

            func setEncryption(policy: EncryptionPolicy) {
                UserPreferences.encryptionPolicy = policy
                weakSelf?.updateData()
            }

            alert.addAction(UIAlertAction(title: EncryptionPolicy.enabled.name, style: .default, handler: { _ in setEncryption(policy: .enabled) }))
            alert.addAction(UIAlertAction(title: EncryptionPolicy.forced.name, style: .default, handler: { _ in setEncryption(policy: .forced) }))
            alert.addAction(UIAlertAction(title: EncryptionPolicy.disabled.name, style: .destructive, handler: { _ in setEncryption(policy: .disabled) }))

            alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel))

            alert.popoverPresentationController?.sourceView = button.superview
            alert.popoverPresentationController?.sourceRect = button.superview!.frame
            alert.popoverPresentationController?.permittedArrowDirections = [.left]

            weakSelf?.present(alert, animated: true)
        }))
        data.append(Section(rowModels: encryption, header: "Settings.Network.Encryption"))

        // MARK: - Network
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
        
        // MARK: - Port
        var port = [CellModelProtocol]()
        port.append(SwitchCell.Model(title: "Settings.Network.DefauldPort", defaultValue: { UserPreferences.defaultPort }, hint: "Settings.Network.DefauldPort.Hint") { switcher in
            UserPreferences.defaultPort = switcher.isOn
            TorrentSdk.applySettingsPack(settingsPack: SettingsPack.userPrefered)
            weakSelf?.updateData()
        })
        port.append(TextFieldCell.Model(title: "Settings.Network.PortFirst", placeholder: "6881", defaultValue: { String(UserPreferences.portRangeFirst) }, keyboardType: .numberPad, hiddenCondition: { UserPreferences.defaultPort }, textEditEndAction: { port in
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
        }))
        port.append(TextFieldCell.Model(title: "Settings.Network.PortSecond", placeholder: "6891", defaultValue: { String(UserPreferences.portRangeSecond) }, keyboardType: .numberPad, hiddenCondition: { UserPreferences.defaultPort }, textEditEndAction: { port in
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
        }))
        data.append(Section(rowModels: port, header: "Settings.Network.Port"))
        
        // MARK: - Interface
        var interface = [CellModelProtocol]()
        interface.append(ButtonCell.Model(title: "Settings.Network.Interface.Title", hint: "Settings.Network.Interface.Hint", buttonTitleFunc: { UserPreferences.interfaceType.name }, action: { button in
            let alert = ThemedUIAlertController(title: "Settings.Network.Interface.Select".localized, message: nil, preferredStyle: .actionSheet)
            
            func setInterface(type: InterfaceType) {
                UserPreferences.interfaceType = type
                weakSelf?.updateData()
            }
            
            alert.addAction(UIAlertAction(title: InterfaceType.all.name, style: .default, handler: { _ in setInterface(type: .all) }))
            alert.addAction(UIAlertAction(title: InterfaceType.primary.name, style: .default, handler: { _ in setInterface(type: .primary) }))
            alert.addAction(UIAlertAction(title: InterfaceType.vpnOnly.name, style: .default, handler: { _ in setInterface(type: .vpnOnly) }))
            alert.addAction(UIAlertAction(title: "InterfaceType.Manual".localized, style: .default, handler: { _ in
                let manual = ThemedUIAlertController(title: nil, message: "Settings.Network.Interface.SelectInterface".localized, preferredStyle: .actionSheet)
                Utils.interfaceNames().forEach { interface in
                    manual.addAction(UIAlertAction(title: interface, style: .default, handler: { _ in
                        setInterface(type: .manual(name: interface))
                    }))
                }
                manual.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel))
                
                manual.popoverPresentationController?.sourceView = button.superview
                manual.popoverPresentationController?.sourceRect = button.superview!.frame
                manual.popoverPresentationController?.permittedArrowDirections = [.left]
                
                weakSelf?.present(manual, animated: true)
            }))
            alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel))
            
            alert.popoverPresentationController?.sourceView = button.superview
            alert.popoverPresentationController?.sourceRect = button.superview!.frame
            alert.popoverPresentationController?.permittedArrowDirections = [.left]
            
            weakSelf?.present(alert, animated: true)
        }))
        data.append(Section(rowModels: interface, header: "Settings.Network.Interface"))
    }
}
