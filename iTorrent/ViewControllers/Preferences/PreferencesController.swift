//
//  PreferencesController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 02.09.2019.
//  Copyright © 2019  XITRIX. All rights reserved.
//

import UIKit

class PreferencesController: StaticTableViewController {
    var onScreenPopup: PopupView?

    deinit {
        print("PreferencesController Deinit")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Localize.get("Settings.Title")

        // APPEARANCE
        var appearance = [CellModelProtocol]()
        appearance.append(SegueCell.Model(self, title: "Settings.Order", controllerType: SettingsSortingController.self))
        if #available(iOS 13, *) {
            appearance.append(SwitchCell.Model(title: "Settings.AutoTheme", defaultValue: { UserPreferences.autoTheme },
                                               action: { switcher in
                                                   let oldTheme = Themes.current
                                                   UserPreferences.autoTheme = switcher.isOn
                                                   Themes.shared.currentUserTheme = UIApplication.shared.keyWindow?.traitCollection.userInterfaceStyle.rawValue
                                                   let newTheme = Themes.current

                                                   if oldTheme != newTheme {
                                                       self.navigationController?.view.isUserInteractionEnabled = false
                                                       DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2) {
                                                           CircularAnimation.animate(startingPoint: switcher.superview!.convert(switcher.center, to: nil))
                                                           self.tableView.reloadData()
                                                           self.navigationController?.view.isUserInteractionEnabled = true
                                                       }
                                                   } else {
                                                       if let rvc = UIApplication.shared.keyWindow?.rootViewController as? Themed {
                                                           rvc.themeUpdate()
                                                       }
                                                       if !switcher.isOn {
                                                           self.tableView.insertRows(at: [IndexPath(row: 2, section: 0)], with: .automatic)
                                                       } else {
                                                           self.tableView.deleteRows(at: [IndexPath(row: 2, section: 0)], with: .automatic)
                                                       }
                                                   }
                }))
        }
        appearance.append(SwitchCell.Model(title: "Settings.Theme",
                                           defaultValue: { UserPreferences.themeNum == 1 },
                                           hiddenCondition: { UserPreferences.autoTheme }) { switcher in
                self.navigationController?.view.isUserInteractionEnabled = false
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2) {
                    UserPreferences.themeNum = switcher.isOn ? 1 : 0
                    CircularAnimation.animate(startingPoint: switcher.superview!.convert(switcher.center, to: nil))
                    self.navigationController?.view.isUserInteractionEnabled = true
                }
        })
        data.append(Section(rowModels: appearance))

        // STORAGE
        var storage = [CellModelProtocol]()
        storage.append(StoragePropertyCell.Model())
        storage.append(SwitchCell.Model(title: "Settings.Storage.Allocate", defaultValue: { UserPreferences.storagePreallocation }, hint: "Settings.Storage.Allocate.Hint") { switcher in
            UserPreferences.storagePreallocation = switcher.isOn
            set_storage_preallocation(switcher.isOn ? 1 : 0)
        })
        data.append(Section(rowModels: storage, header: "Settings.Storage.Header"))

        // BACKGROUND
        var background = [CellModelProtocol]()
        background.append(SwitchCell.Model(title: "Settings.BackgroundEnable", defaultValue: { UserPreferences.background }) { switcher in
            UserPreferences.background = switcher.isOn
            self.tableView.reloadData()
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
                    self.present(controller, animated: true)
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
                self.onScreenPopup?.dismiss()
                self.onScreenPopup = TimeLimitPicker(defaultValue: UserPreferences.zeroSpeedLimit / 60, dataSelected: { res in
                    if res == 0 {
                        button.setTitle(NSLocalizedString("Disabled", comment: ""), for: .normal)
                    } else {
                        button.setTitle("\(res / 60) \(Localize.getTermination("minute", res / 60))", for: .normal)
                    }
                }, dismissAction: { res in
                    UserPreferences.zeroSpeedLimit = res
            })
                self.onScreenPopup?.show(self)
        })
        data.append(Section(rowModels: background, header: "Settings.BackgroundHeader", footer: "Settings.BackgroundFooter"))

        // SPEED LIMITATION
        var speed = [CellModelProtocol]()
        speed.append(ButtonCell.Model(title: "Settings.DownLimit",
                                      buttonTitleFunc: { UserPreferences.downloadLimit == 0 ?
                                          NSLocalizedString("Unlimited", comment: "") :
                                          Utils.getSizeText(size: UserPreferences.downloadLimit, decimals: true) + "/S"
                }) { button in
                self.onScreenPopup?.dismiss()
                self.onScreenPopup = SpeedPicker(defaultValue: UserPreferences.downloadLimit, dataSelected: { res in
                    if res == 0 {
                        button.setTitle(NSLocalizedString("Unlimited", comment: ""), for: .normal)
                    } else {
                        button.setTitle(Utils.getSizeText(size: res, decimals: true) + "/S", for: .normal)
                    }
                }, dismissAction: { res in
                    UserPreferences.downloadLimit = res
                    set_download_limit(Int32(res))
            })
                self.onScreenPopup?.show(self)
        })
        speed.append(ButtonCell.Model(title: "Settings.UpLimit",
                                      buttonTitleFunc: { UserPreferences.uploadLimit == 0 ?
                                          NSLocalizedString("Unlimited", comment: "") :
                                          Utils.getSizeText(size: UserPreferences.uploadLimit, decimals: true) + "/S"
                }) { button in
                self.onScreenPopup?.dismiss()
                self.onScreenPopup = SpeedPicker(defaultValue: UserPreferences.uploadLimit, dataSelected: { res in
                    if res == 0 {
                        button.setTitle(NSLocalizedString("Unlimited", comment: ""), for: .normal)
                    } else {
                        button.setTitle(Utils.getSizeText(size: res, decimals: true) + "/S", for: .normal)
                    }
                }, dismissAction: { res in
                    UserPreferences.uploadLimit = res
                    set_upload_limit(Int32(res))
            })
                self.onScreenPopup?.show(self)
        })
        data.append(Section(rowModels: speed, header: "Settings.SpeedHeader"))

        // FTP
        var ftp = [CellModelProtocol]()
        ftp.append(SwitchCell.Model(title: "Settings.FTPEnable", defaultValue: { UserPreferences.ftpKey }, hint: Localize.get("Settings.FTPEnable.Hint")) { switcher in
            UserPreferences.ftpKey = switcher.isOn
            switcher.isOn ? Core.shared.startFileSharing() : Core.shared.stopFileSharing()
            self.tableView.reloadSections([4], with: .automatic)
        })
        ftp.append(SegueCell.Model(self, title: "Settings.FTP.Settings", controllerType: PreferencesWebDavController.self))
        data.append(Section(rowModels: ftp, header: "Settings.FTPHeader", footerFunc: { () -> (String) in
            if UserPreferences.ftpKey,
                UserPreferences.webDavWebServerEnabled {
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

        // NOTIFICATIONS
        var notifications = [CellModelProtocol]()
        notifications.append(SwitchCell.Model(title: "Settings.NotifyFinishLoad", defaultValue: { UserPreferences.notificationsKey }) { switcher in
            UserPreferences.notificationsKey = switcher.isOn
            self.tableView.reloadData()
        })
        notifications.append(SwitchCell.Model(title: "Settings.NotifyFinishSeed", defaultValue: { UserPreferences.notificationsSeedKey }) { switcher in
            UserPreferences.notificationsSeedKey = switcher.isOn
            self.tableView.reloadData()
               })
        notifications.append(SwitchCell.Model(title: "Settings.NotifyBadge", defaultValue: { UserPreferences.badgeKey }, disableCondition: { !UserPreferences.notificationsKey && !UserPreferences.notificationsSeedKey }) { switcher in
            UserPreferences.badgeKey = switcher.isOn
            self.tableView.reloadData()
                      })
        data.append(Section(rowModels: notifications, header: "Settings.NotifyHeader"))

        // UPDATES
        var updates = [CellModelProtocol]()
        updates.append(ButtonCell.Model(title: "Settings.UpdateSite", buttonTitle: "Settings.UpdateSite.Open") { _ in
            Utils.openUrl("https://github.com/XITRIX/iTorrent")
        })
        updates.append(UpdateInfoCell.Model {
            self.present(Dialogs.crateUpdateDialog(forced: true)!, animated: true)
        })
        let version = try? String(contentsOf: Bundle.main.url(forResource: "Version", withExtension: "ver")!)
        data.append(Section(rowModels: updates, header: "Settings.UpdateHeader", footer: NSLocalizedString("Current app version: ", comment: "") + (version ?? "Unknown")))

        // DONATES
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
                            Dialogs.withTimer(self, title: nil, message: Localize.get("Copied CC # to clipboard!"))
                        }
                    }
                }
            }
            let paypal = UIAlertAction(title: "PayPal", style: .default) { _ in
                Utils.openUrl("https://paypal.me/xitrix")
            }
            let liberapay = UIAlertAction(title: "Liberapay", style: .default) { _ in
                Utils.openUrl("https://liberapay.com/XITRIX")
            }
            let kofi = UIAlertAction(title: "Ko-fi", style: .default) { _ in
                Utils.openUrl("https://ko-fi.com/xitrix")
            }
            let cancel = UIAlertAction(title: Localize.get("Cancel"), style: .cancel)

            alert.addAction(card)
            alert.addAction(paypal)
            alert.addAction(liberapay)
            alert.addAction(kofi)
            alert.addAction(cancel)

            self.present(alert, animated: true)
        })
        donates.append(SegueCell.Model(self, title: "Patreon", segueViewId: "PatreonViewController"))
        data.append(Section(rowModels: donates, header: "Settings.DonateHeader", footer: "Settings.DonateFooter"))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(true, animated: false)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onScreenPopup?.dismiss()
    }
}
