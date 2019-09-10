//
//  ThemedUINavigationController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 04/06/2019.
//  Copyright © 2019  XITRIX. All rights reserved.
//

import UIKit

class ThemedUINavigationController : UINavigationController, Themed {
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(themeUpdate), name: Themes.updateNotification, object: nil)
        themeUpdate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        themeUpdate()
    }
    
    @objc func themeUpdate() {
        let theme = Themes.current
        
        if #available(iOS 13.0, *) {
            let i = UIUserInterfaceStyle(rawValue: theme.overrideUserInterfaceStyle!)!
            overrideUserInterfaceStyle = i
        }
        
        navigationBar.barStyle = theme.barStyle
        toolbar.barStyle = theme.barStyle
        toolbar.tintColor = navigationBar.tintColor
        
        let f = toolbar.frame
        toolbar.frame = CGRect(x: f.origin.x, y: f.origin.y, width: f.size.width, height: 44)
        
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return Themes.current.statusBarStyle
    }
}
