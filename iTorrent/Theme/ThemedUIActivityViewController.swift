//
//  ThemedUIActivityViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 05/06/2019.
//  Copyright © 2019  XITRIX. All rights reserved.
//

import UIKit

class ThemedUIActivityViewController : UIActivityViewController, Themed {
    override func viewDidLoad() {
        super.viewDidLoad()
        themeUpdate()
    }
    
    func themeUpdate() {
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = UIUserInterfaceStyle(rawValue: Themes.current.overrideUserInterfaceStyle!)!
        }
    }
}
