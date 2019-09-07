//
//  ThemedUISplitViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 13/07/2019.
//  Copyright © 2019  XITRIX. All rights reserved.
//

import UIKit

class ThemedUISplitViewController : UISplitViewController, Themed {
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
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return Themes.current().statusBarStyle
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13.0, *) {
            let hasUserInterfaceStyleChanged = previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) ?? true
            if (hasUserInterfaceStyleChanged) {
                Themes.shared.currentUserTheme = traitCollection.userInterfaceStyle.rawValue
                if (UserPreferences.autoTheme.value) {
                    NotificationCenter.default.post(name: Themes.updateNotification, object: nil)
                }
            }
        }
    }
}
