//
//  ThemedUINavigationController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 04/06/2019.
//  Copyright © 2019  XITRIX. All rights reserved.
//

import UIKit

class ThemedUINavigationController: SANavigationController, Themed {
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
            let interface = UIUserInterfaceStyle(rawValue: theme.overrideUserInterfaceStyle!)!
            overrideUserInterfaceStyle = interface
        }

        navigationBar.barStyle = theme.barStyle
        toolbar.barStyle = theme.barStyle
        navigationBar.tintColor = theme.tintColor
        toolbar.tintColor = theme.tintColor

        let frame = toolbar.frame
        toolbar.frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.size.width, height: 44)

        setNeedsStatusBarAppearanceUpdate()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        Themes.current.statusBarStyle
    }
}
