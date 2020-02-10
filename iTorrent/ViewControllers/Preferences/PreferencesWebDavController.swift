//
//  PreferencesWebDavController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 10.11.2019.
//  Copyright © 2019  XITRIX. All rights reserved.
//

import UIKit

class PreferencesWebDavController : StaticTableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Localize.get("Settings.FTPHeader")
        
        var pass = [CellModelProtocol]()
        pass.append(TextFieldCell.Model(title: "Settings.FTP.WebDav.Username", placeholder: "Settings.FTP.WebDav.Username.Placeholder", defaultValue: {UserPreferences.webDavUsername.value}) { username in
            UserPreferences.webDavUsername.value = username
        })
        pass.append(TextFieldCell.Model(title: "Settings.FTP.WebDav.Password", placeholder: "Settings.FTP.WebDav.Password.Placeholder", defaultValue: {UserPreferences.webDavPassword.value}, isPassword: true) { password in
            UserPreferences.webDavPassword.value = password
        })
        data.append(Section(rowModels: pass, footer: "Settings.FTP.WebDav.PassText"))
        
        var web = [CellModelProtocol]()
        web.append(SwitchCell.ModelProperty(title: "Enable", property: UserPreferences.webDavWebServerEnabled) { switcher in
            if switcher.isOn {
                if UserPreferences.ftpKey.value {
                    Manager.startFileSharing()
                }
            } else {
                if Manager.webUploadServer.isRunning {
                    Manager.webUploadServer.stop()
                }
            }
            self.view.endEditing(true)
        })
        data.append(Section(rowModels: web, header: "Settings.FTP.WebDav.WebTitle", footer: "Settings.FTP.WebDav.WebText"))
        
        var webDav = [CellModelProtocol]()
        webDav.append(SwitchCell.ModelProperty(title: "Enable", property: UserPreferences.webDavWebDavServerEnabled) { switcher in
            if switcher.isOn {
                if UserPreferences.ftpKey.value {
                    Manager.startFileSharing()
                }
            } else {
                if Manager.webDAVServer.isRunning {
                    Manager.webDAVServer.stop()
                }
            }
            self.tableView.reloadData()
        })
        webDav.append(TextFieldCell.Model(title: "Settings.FTP.WebDav.WebDavPort", placeholder: "81", defaultValue: {String(UserPreferences.webDavPort.value)}, keyboardType: .numberPad) { port in
            if let intPort = Int(port) {
                UserPreferences.webDavPort.value = intPort
            } else {
                UserPreferences.webDavPort.value = 81
            }
        })
        data.append(Section(rowModels: webDav, header: "Settings.FTP.WebDav.WebDavTitle", footerFunc: { () -> String in
            let addr = Manager.webDAVServer.serverURL?.absoluteString
            let res = addr != nil ? ": \(addr!)" : ""
            return "\(Localize.get("Settings.FTP.WebDav.WebDavText"))\(res)"
        }))
    }
    
    deinit {
        print("PreferencesWebDavController Deinit")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidChangeFrame), name: UIWindow.keyboardDidChangeFrameNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIWindow.keyboardDidChangeFrameNotification, object: nil)
    }
    
    @objc func keyboardDidChangeFrame(notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
            let animationDuration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue {
        
            var loadingInset = tableView.contentInset
            loadingInset.bottom = keyboardSize.height

            let contentOffset = tableView.contentOffset

            UIView.animate(withDuration: animationDuration) {
                self.tableView.contentInset = loadingInset
                self.tableView.scrollIndicatorInsets = loadingInset
                self.tableView.contentOffset = contentOffset
            }
        }
    }
}
