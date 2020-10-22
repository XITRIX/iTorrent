//
//  PreferencesController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 02.09.2019.
//  Copyright © 2019  XITRIX. All rights reserved.
//

import ITorrentFramework
import UIKit

class PreferencesController: StaticTableViewController {
    override var toolBarIsHidden: Bool? {
        true
    }

    var onScreenPopup: PopupViewController?

    deinit {
        print("PreferencesController Deinit")
    }

    override func initSections() {
        title = Localize.get("Settings.Title")

        weak var weakSelf = self

        // -MARK: APPEARANCE
        var appearance = [CellModelProtocol]()
        appearance.append(SegueCell.Model(weakSelf, title: "Settings.Order", controllerType: SortingPreferencesController.self))
        if #available(iOS 13, *) {
            appearance.append(SwitchCell.Model(title: "Settings.AutoTheme", defaultValue: { UserPreferences.autoTheme },
                                               action: { switcher in
                                                   let oldTheme = Themes.current
                                                   UserPreferences.autoTheme = switcher.isOn
                                                   Themes.shared.currentUserTheme = UIScreen.main.traitCollection.userInterfaceStyle.rawValue
                                                   let newTheme = Themes.current

                                                   if oldTheme != newTheme {
                                                       weakSelf?.navigationController?.view.isUserInteractionEnabled = false
                                                       DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2) {
                                                           CircularAnimation.animate(startingPoint: switcher.superview!.convert(switcher.center, to: nil))
                                                           weakSelf?.updateData(animated: false)
                                                           weakSelf?.navigationController?.view.isUserInteractionEnabled = true
                                                       }
                                                   } else {
                                                       if let rvc = UIApplication.shared.keyWindow?.rootViewController as? Themed {
                                                           rvc.themeUpdate()
                                                       }
                                                       weakSelf?.updateData()
                                                   }
                                               }))
        } else {
            UserPreferences.autoTheme = false
        }
        appearance.append(SwitchCell.Model(title: "Settings.Theme",
                                           defaultValue: { UserPreferences.themeNum == 1 },
                                           hiddenCondition: { UserPreferences.autoTheme }) { switcher in
                weakSelf?.navigationController?.view.isUserInteractionEnabled = false
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2) {
                    UserPreferences.themeNum = switcher.isOn ? 1 : 0
                    CircularAnimation.animate(startingPoint: switcher.superview!.convert(switcher.center, to: nil))
                    weakSelf?.navigationController?.view.isUserInteractionEnabled = true
                }
            })
        data.append(Section(rowModels: appearance, header: "Settings.Appearance.Header"))

        // -MARK: STORAGE
        var storage = [CellModelProtocol]()
        storage.append(StoragePropertyCell.Model())
        storage.append(SwitchCell.Model(title: "Settings.Storage.Allocate", defaultValue: { UserPreferences.storagePreallocation }, hint: "Settings.Storage.Allocate.Hint") { switcher in
            UserPreferences.storagePreallocation = switcher.isOn
            TorrentSdk.setStoragePreallocation(allocate: switcher.isOn)
        })
        data.append(Section(rowModels: storage, header: "Settings.Storage.Header"))

        // -MARK: BACKGROUND
        var background = [CellModelProtocol]()
        background.append(SwitchCell.Model(title: "Settings.BackgroundEnable", defaultValue: { UserPreferences.background }) { switcher in
            UserPreferences.background = switcher.isOn
            weakSelf?.updateData()
        })
        background.append(SwitchCell.Model(title: "Settings.BackgroundSeeding",
                                           defaultValue: { UserPreferences.backgroundSeedKey },
                                           switchColor: #colorLiteral(red: 1, green: 0.2980392157, blue: 0.168627451, alpha: 1),
                                           disableCondition: { !UserPreferences.background }) { switcher in
                if switcher.isOn {
                    let controller = ThemedUIAlertController(title: Localize.get("WARNING"), message: Localize.get("Settings.BackgroundSeeding.Warning"), preferredStyle: .alert)
                    let enable = UIAlertAction(title: Localize.get("Enable"), style: .destructive) { _ in
                        UserPreferences.backgroundSeedKey = switcher.isOn
                    }
                    let close = UIAlertAction(title: Localize.get("Cancel"), style: .cancel) { _ in
                        switcher.setOn(false, animated: true)
                    }
                    controller.addAction(enable)
                    controller.addAction(close)
                    weakSelf?.present(controller, animated: true)
                } else {
                    UserPreferences.seedBackgroundWarning = false
                    UserPreferences.backgroundSeedKey = false
                }
            })
        background.append(ButtonCell.Model(title: "Settings.ZeroSpeedLimit",
                                           hint: Localize.get("Settings.ZeroSpeedLimit.Hint"),
                                           buttonTitleFunc: {
                                               UserPreferences.zeroSpeedLimit == 0 ?
                                                   NSLocalizedString("Disabled", comment: "") :
                                                   "\(UserPreferences.zeroSpeedLimit / 60) \(Localize.getTermination("minute", UserPreferences.zeroSpeedLimit / 60))"
                                           }) { button in
                weakSelf?.onScreenPopup?.dismiss()
                weakSelf?.onScreenPopup = TimeLimitPicker(defaultValue: UserPreferences.zeroSpeedLimit / 60, dataSelected: { res in
                    if res == 0 {
                        button.setTitle(NSLocalizedString("Disabled", comment: ""), for: .normal)
                    } else {
                        button.setTitle("\(res / 60) \(Localize.getTermination("minute", res / 60))", for: .normal)
                    }
                }, dismissAction: { res in
                    UserPreferences.zeroSpeedLimit = res
                })

                guard let self = weakSelf else { return }
                self.onScreenPopup?.show(in: self)
            })
        data.append(Section(rowModels: background, header: "Settings.BackgroundHeader")) // , footer: "Settings.BackgroundFooter"))

        // -MARK: SPEED LIMITATION
        var speed = [CellModelProtocol]()
        speed.append(ButtonCell.Model(title: "Settings.DownLimit",
                                      buttonTitleFunc: { UserPreferences.downloadLimit == 0 ?
                                          NSLocalizedString("Unlimited", comment: "") :
                                          Utils.getSizeText(size: Int64(UserPreferences.downloadLimit), decimals: true) + "/S"
                                      }) { button in
                weakSelf?.onScreenPopup?.dismiss()
                weakSelf?.onScreenPopup = SpeedPicker(defaultValue: Int64(UserPreferences.downloadLimit), dataSelected: { res in
                    if res == 0 {
                        button.setTitle(NSLocalizedString("Unlimited", comment: ""), for: .normal)
                    } else {
                        button.setTitle(Utils.getSizeText(size: res, decimals: true) + "/S", for: .normal)
                    }
                }, dismissAction: { res in
                    UserPreferences.downloadLimit = Int(res)
                    TorrentSdk.applySettingsPack(settingsPack: SettingsPack.userPrefered)
                })

                guard let self = weakSelf else { return }
                self.onScreenPopup?.show(in: self)
            })
        speed.append(ButtonCell.Model(title: "Settings.UpLimit",
                                      buttonTitleFunc: { UserPreferences.uploadLimit == 0 ?
                                          NSLocalizedString("Unlimited", comment: "") :
                                          Utils.getSizeText(size: Int64(UserPreferences.uploadLimit), decimals: true) + "/S"
                                      }) { button in
                weakSelf?.onScreenPopup?.dismiss()
                weakSelf?.onScreenPopup = SpeedPicker(defaultValue: Int64(UserPreferences.uploadLimit), dataSelected: { res in
                    if res == 0 {
                        button.setTitle(NSLocalizedString("Unlimited", comment: ""), for: .normal)
                    } else {
                        button.setTitle(Utils.getSizeText(size: res, decimals: true) + "/S", for: .normal)
                    }
                }, dismissAction: { res in
                    UserPreferences.uploadLimit = Int(res)
                    TorrentSdk.applySettingsPack(settingsPack: SettingsPack.userPrefered)
                })

                guard let self = weakSelf else { return }
                self.onScreenPopup?.show(in: self)
            })
        data.append(Section(rowModels: speed, header: "Settings.SpeedHeader"))

        // -MARK: DATA SHARING
        var ftp = [CellModelProtocol]()
        ftp.append(SwitchCell.Model(title: "Settings.FTPEnable", defaultValue: { UserPreferences.ftpKey }, hint: Localize.get("Settings.FTPEnable.Hint")) { switcher in
            UserPreferences.ftpKey = switcher.isOn
            switcher.isOn ? Core.shared.startFileSharing() : Core.shared.stopFileSharing()
            weakSelf?.updateData(animated: false)
        })
        ftp.append(SegueCell.Model(weakSelf, title: "Settings.FTP.Settings", controllerType: WebDavPreferencesController.self))
        data.append(Section(rowModels: ftp, header: "Settings.FTPHeader", footerFunc: { () -> (String) in
            if UserPreferences.ftpKey,
                UserPreferences.webServerEnabled
            {
                let addr = Core.shared.webUploadServer.serverURL // Utils.getWiFiAddress()
                if let addr = addr?.absoluteString {
                    return UserPreferences.ftpKey ? Localize.get("Settings.FTP.Message") + addr : ""
                } else {
                    return Localize.get("Settings.FTP.Message.NoNetwork")
                }
            } else {
                return ""
            }
        }))

        // -MARK: NETWORK

        var network = [CellModelProtocol]()
        network.append(SegueCell.Model(weakSelf, title: "Settings.Network.Proxy", controllerType: ProxyPreferencesController.self))
        network.append(SegueCell.Model(weakSelf, title: "Settings.Network.Connection", controllerType: NetworkPreferencesController.self))
        data.append(Section(rowModels: network, header: "Settings.Network.Header"))

        // -MARK: NOTIFICATIONS
        var notifications = [CellModelProtocol]()
        notifications.append(SwitchCell.Model(title: "Settings.NotifyFinishLoad", defaultValue: { UserPreferences.notificationsKey }) { switcher in
            UserPreferences.notificationsKey = switcher.isOn
            weakSelf?.updateData()
        })
        notifications.append(SwitchCell.Model(title: "Settings.NotifyFinishSeed", defaultValue: { UserPreferences.notificationsSeedKey }) { switcher in
            UserPreferences.notificationsSeedKey = switcher.isOn
            weakSelf?.updateData()
        })
        notifications.append(SwitchCell.Model(title: "Settings.NotifyBadge", defaultValue: { UserPreferences.badgeKey }, disableCondition: { !UserPreferences.notificationsKey && !UserPreferences.notificationsSeedKey }) { switcher in
            UserPreferences.badgeKey = switcher.isOn
            weakSelf?.updateData()
        })
        data.append(Section(rowModels: notifications, header: "Settings.NotifyHeader"))

        // -MARK: UPDATES
        var updates = [CellModelProtocol]()
        updates.append(ButtonCell.Model(title: "Settings.UpdateSite", buttonTitle: "Settings.UpdateSite.Open") { _ in
            Utils.openUrl("https://github.com/XITRIX/iTorrent")
        })
        updates.append(UpdateInfoCell.Model(tapAction: {
            weakSelf?.present(Dialog.createUpdateLogs(forced: true)!, animated: true)
        }))
        let version = try? String(contentsOf: Bundle.main.url(forResource: "Version", withExtension: "ver")!)
        data.append(Section(rowModels: updates, header: "Settings.UpdateHeader", footer: NSLocalizedString("Current app version: ", comment: "") + (version ?? "Unknown")))

        // -MARK: DONATES
        var donates = [CellModelProtocol]()
        donates.append(SegueCell.Model(title: "Settings.DonateCard.DonatePlatforms") {
            let alert = ThemedUIAlertController(title: Localize.get("Settings.DonateCard.DonatePlatforms.Title"), message: "", preferredStyle: .alert)

            let card = UIAlertAction(title: Localize.get("Settings.DonateCard"), style: .default) { _ in
                DispatchQueue.global(qos: .background).async {
                    if let url = URL(string: "https://raw.githubusercontent.com/XITRIX/iTorrent/master/iTorrent/Credit.card") {
                        var card = ""
                        do {
                            card = try String(contentsOf: url)
                        } catch {
                            card = "4817760222220562"
                        }

                        DispatchQueue.main.async {
                            UIPasteboard.general.string = card
                            Dialog.withTimer(weakSelf, title: nil, message: Localize.get("Copied CC # to clipboard!"))
                        }
                    }
                }
            }
            let paypal = UIAlertAction(title: "PayPal", style: .default) { _ in
                Utils.openUrl("https://paypal.me/xitrix")
            }
            let cancel = UIAlertAction(title: Localize.get("Cancel"), style: .cancel)

            alert.addAction(card)
            alert.addAction(paypal)
            alert.addAction(cancel)

            weakSelf?.present(alert, animated: true)
        })
        donates.append(SegueCell.Model(weakSelf, title: "Patreon", segueViewId: "PatreonViewController"))
        data.append(Section(rowModels: donates, header: "Settings.DonateHeader", footer: "Settings.DonateFooter"))
        
        // -MARK: DEBUG
//        var debug = [CellModelProtocol]()
//        debug.append(ButtonCell.Model(title: "Interfaces", buttonTitle: "Show", action: { _ in
//            let interfaces = Utils.interfaceNames()
//            Dialog.show(title: "Interfaces", message: interfaces.joined(separator: "\n"))
//        }))
//        data.append(Section(rowModels: debug, header: "Debug"))
    }
}
