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
        
        var web = [CellModelProtocol]()
        web.append(SwitchCell.ModelProperty(title: "Web", property: UserPreferences.ftpWebKey) { switcher in
            
        })
        data.append(Section(rowModels: web))
        
        var webDav = [CellModelProtocol]()
        webDav.append(SwitchCell.ModelProperty(title: "WebDAV", property: UserPreferences.ftpWebDavKey) { switcher in
            
        })
        data.append(Section(rowModels: webDav, header: "WebDAV"))
    }
}
