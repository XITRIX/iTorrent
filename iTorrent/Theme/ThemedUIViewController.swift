//
//  ThemedUIViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 24/06/2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import UIKit

class ThemedUIViewController: SAViewController, Themed {
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(themeUpdate), name: Themes.updateNotification, object: nil)
        themeUpdate()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //themeUpdate()
    }

    @objc func themeUpdate() {
        let theme = Themes.current

        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = UIUserInterfaceStyle(rawValue: theme.overrideUserInterfaceStyle!)!
        }

        view.backgroundColor = theme.backgroundSecondary
    }
}
