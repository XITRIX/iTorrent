//
//  PreferencesController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 02.09.2019.
//  Copyright © 2019  XITRIX. All rights reserved.
//

import UIKit

class PreferencesController : ThemedUIViewController {
    @IBOutlet var tableView: UITableView!
    
    var data : [Section] = []
    var onScreenPopup : PopupView?
    
    var _presentableData : [Section]?
    var presentableData : [Section] {
        get {
            if (_presentableData == nil) { _presentableData = [Section]() }
            _presentableData?.removeAll()
            data.forEach { _presentableData?.append(Section(rowModels: $0.rowModels.filter({ !($0.hiddenCondition?() ?? false)}), header: $0.header, footer: $0.footer)) }
            return _presentableData!
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // APPEARENCE
        var appearence = [CellModelProtocol]()
        appearence.append(SegueCell.Model(title: "Settings.Order"))
        appearence.append(SwitchCell.ModelProperty(title: "Settings.AutoTheme", property: UserPreferences.autoTheme,
                                                   hiddenCondition: {
                                                    if #available(iOS 13, *) {
                                                        return false
                                                    }
                                                    return true
                                                   },
                                                   action: { switcher in
                                                    UIView.transition(with: self.tableView, duration: 0.1, options: .transitionCrossDissolve, animations: {
                                                        NotificationCenter.default.post(name: Themes.updateNotification, object: nil)
                                                        self.tableView.reloadData()
                                                    })
        }))
        appearence.append(SwitchCell.Model(title: "Settings.Theme",
                                           defaultValue: { UserPreferences.themeNum.value == 1 },
                                           hiddenCondition: { UserPreferences.autoTheme.value }) { switcher in
                                            UserPreferences.themeNum.value = switcher.isOn ? 1 : 0
                                            UIView.animate(withDuration: 0.1) {
                                                NotificationCenter.default.post(name: Themes.updateNotification, object: nil)
                                            }
        })
        data.append(PreferencesController.Section(rowModels: appearence))
        
        //BACKGROUND
        var background = [CellModelProtocol]()
        background.append(SwitchCell.ModelProperty(title: "Settings.BackgroundEnable", property: UserPreferences.background) { _ in self.tableView.reloadData() })
        background.append(SwitchCell.Model(title: "Settings.BackgroundSeeding", defaultValue: { UserPreferences.backgroundSeedKey.value }, switchColor: #colorLiteral(red: 1, green: 0.2980392157, blue: 0.168627451, alpha: 1), disableCondition: { !UserPreferences.background.value }){ switcher in
            if (switcher.isOn) {
                let controller = ThemedUIAlertController(title: NSLocalizedString("WARNING", comment: ""), message: NSLocalizedString("This will let iTorrent run in in the background indefinitely, in case any torrent is seeding without limits, which can cause significant battery drain. \n\nYou will need to force close the app to stop this!", comment: ""), preferredStyle: .alert)
                let enable = UIAlertAction(title: NSLocalizedString("Enable", comment: ""), style: .destructive) { _ in
                    UserPreferences.backgroundSeedKey.value = switcher.isOn
                }
                let close = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { _ in
                    switcher.setOn(false, animated: true)
                }
                controller.addAction(enable)
                controller.addAction(close)
                self.present(controller, animated: true)
            } else {
                UserPreferences.seedBackgroundWarning.value = false
                UserPreferences.backgroundSeedKey.value = false
            }
        })
        data.append(PreferencesController.Section(rowModels: background, header: "Settings.BackgroundHeader", footer: "Settings.BackgroundFooter"))
        
        //SPEED LIMITATION
        var speed = [CellModelProtocol]()
        speed.append(ButtonCell.Model(title: "Settings.DownLimit",
                                      buttonTitle: UserPreferences.downloadLimit.value == 0 ?
                                        NSLocalizedString("Unlimited", comment: "") :
                                        Utils.getSizeText(size: UserPreferences.downloadLimit.value, decimals: true) + "/S")
        { button in
            self.onScreenPopup?.dismiss()
            self.onScreenPopup = SpeedPicker(defaultValue: UserPreferences.downloadLimit.value, dataSelected: { res in
                if (res == 0) {
                    button.setTitle(NSLocalizedString("Unlimited", comment: ""), for: .normal)
                } else {
                    button.setTitle(Utils.getSizeText(size: res, decimals: true) + "/S", for: .normal)
                }
            }, dismissAction: { res in
                UserPreferences.downloadLimit.value = res
                set_download_limit(Int32(res))
            })
            self.onScreenPopup?.show(self)
        })
        speed.append(ButtonCell.Model(title: "Settings.UpLimit",
                                      buttonTitle: UserPreferences.uploadLimit.value == 0 ?
                                        NSLocalizedString("Unlimited", comment: "") :
                                        Utils.getSizeText(size: UserPreferences.uploadLimit.value, decimals: true) + "/S")
        { button in
            self.onScreenPopup?.dismiss()
            self.onScreenPopup = SpeedPicker(defaultValue: UserPreferences.uploadLimit.value, dataSelected: { res in
                if (res == 0) {
                    button.setTitle(NSLocalizedString("Unlimited", comment: ""), for: .normal)
                } else {
                    button.setTitle(Utils.getSizeText(size: res, decimals: true) + "/S", for: .normal)
                }
            }, dismissAction: { res in
                UserPreferences.uploadLimit.value = res
                set_upload_limit(Int32(res))
            })
            self.onScreenPopup?.show(self)
        })
        data.append(PreferencesController.Section(rowModels: speed, header: "Settings.SpeedHeader"))
        
        //FTP
        var ftp = [CellModelProtocol]()
        ftp.append(SwitchCell.ModelProperty(title: "Settings.FTPEnable", property: UserPreferences.ftpKey) { switcher in
            switcher.isOn ? Manager.startFTP() : Manager.stopFTP()
            self.tableView.reloadData()
        })
        ftp.append(SwitchCell.Model(title: "Settings.FTPBackground", defaultValue: { UserPreferences.ftpBackgroundKey.value }, switchColor: #colorLiteral(red: 1, green: 0.2980392157, blue: 0.168627451, alpha: 1)) { switcher in
            if (switcher.isOn) {
                let controller = ThemedUIAlertController(title: NSLocalizedString("WARNING", comment: ""), message: NSLocalizedString("This will let iTorrent run in the background indefinitely, which can cause significant battery drain. \n\nYou will need to force close the app to stop this!", comment: ""), preferredStyle: .alert)
                let enable = UIAlertAction(title: NSLocalizedString("Enable", comment: ""), style: .destructive) { _ in
                    UserPreferences.ftpBackgroundKey.value = switcher.isOn
                }
                let close = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { _ in
                    switcher.setOn(false, animated: true)
                }
                controller.addAction(enable)
                controller.addAction(close)
                self.present(controller, animated: true)
            } else {
                UserPreferences.ftpBackgroundKey.value = switcher.isOn
            }
        })
        data.append(PreferencesController.Section(rowModels: ftp, header: "Settings.FTPHeader"))
        
        //NOTIFICATIONS
        var notifications = [CellModelProtocol]()
        notifications.append(SwitchCell.ModelProperty(title: "Settings.NotifyFinishLoad", property: UserPreferences.notificationsKey) { _ in self.tableView.reloadData() })
        notifications.append(SwitchCell.ModelProperty(title: "Settings.NotifyFinishSeed", property: UserPreferences.notificationsSeedKey) { _ in self.tableView.reloadData() })
        notifications.append(SwitchCell.ModelProperty(title: "Settings.NotifyBadge", property: UserPreferences.badgeKey, disableCondition: { !UserPreferences.notificationsKey.value && !UserPreferences.notificationsSeedKey.value }))
        data.append(PreferencesController.Section(rowModels: notifications, header: "Settings.NotifyHeader"))
        
        //UPDATED
        var updates = [CellModelProtocol]()
        updates.append(ButtonCell.Model(title: "Settings.UpdateSite", buttonTitle: "Settings.UpdateSite.Open") { button in
            func open (scheme: String) {
                if let url = URL(string: scheme) {
                    if #available(iOS 10, *) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                    else {
                        UIApplication.shared.openURL(url)
                    }
                }
            }
            open(scheme: "https://github.com/XITRIX/iTorrent")
        })
        updates.append(UpdateInfoCell.Model {
            self.present(UpdatesDialog.summon(forced: true)!, animated: true)
        })
        let version = try! String(contentsOf: Bundle.main.url(forResource: "Version", withExtension: "ver")!)
        data.append(PreferencesController.Section(rowModels: updates, header: "Settings.UpdateHeader", footer: NSLocalizedString("Current app version: ", comment: "") + version))
        
        //DONATES
        var donates = [CellModelProtocol]()
        donates.append(SwitchCell.Model(title: "Settings.DonateDisable", defaultValue: { UserPreferences.disableAds.value }, switchColor: #colorLiteral(red: 1, green: 0.2980392157, blue: 0.168627451, alpha: 1)) { switcher in
            if (switcher.isOn) {
                let controller = ThemedUIAlertController(title: NSLocalizedString("Supplication", comment: ""), message: NSLocalizedString("If you enjoy this app, consider supporting the developer by keeping the ads on.", comment: ""), preferredStyle: .alert)
                let enable = UIAlertAction(title: NSLocalizedString("Disable Anyway", comment: ""), style: .destructive) { _ in
                    UserPreferences.disableAds.value = switcher.isOn
                }
                let close = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { _ in
                    switcher.setOn(false, animated: true)
                }
                controller.addAction(enable)
                controller.addAction(close)
                self.present(controller, animated: true)
            } else {
                UserPreferences.disableAds.value = switcher.isOn
            }
        })
        donates.append(ButtonCell.Model(title: "Settings.DonateCard", buttonTitle: "Settings.DonateCard.Copy") { button in
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
                        let alert = ThemedUIAlertController(title: nil, message: NSLocalizedString("Copied CC # to clipboard!", comment: ""), preferredStyle: .alert)
                        self.present(alert, animated: true, completion: nil)
                        // change alert timer to 2 seconds, then dismiss
                        let when = DispatchTime.now() + 2
                        DispatchQueue.main.asyncAfter(deadline: when){
                            alert.dismiss(animated: true, completion: nil)
                        }
                    }
                }
            }
        })
        data.append(PreferencesController.Section(rowModels: donates, header: "Settings.DonateHeader"))
        
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(true, animated: false)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onScreenPopup?.dismiss()
    }
    
    struct Section {
        var rowModels : [CellModelProtocol] = []
        var header : String = ""
        var footer : String = ""
    }
}

extension PreferencesController : UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return presentableData.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return presentableData[section].rowModels.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Localize.get(presentableData[section].header)
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return Localize.get(presentableData[section].footer)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = presentableData[indexPath.section].rowModels[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: model.reuseCellIdentifier, for: indexPath)
        (cell as? PreferenceCellProtocol)?.setModel(model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = presentableData[indexPath.section].rowModels[indexPath.row]
        model.tapAction?()
    }
}
