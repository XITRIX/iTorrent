//
//  ThemedUIViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 24/06/2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class ThemedUIViewController : UIViewController, Themed {
    convenience init() {
        self.init(nibName:nil, bundle:nil)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
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
		let theme = UserDefaults.standard.integer(forKey: UserDefaultsKeys.themeNum)
		
		view.backgroundColor = Themes.shared.theme[theme].backgroundSecondary
		navigationController?.navigationBar.barStyle = Themes.shared.theme[theme].barStyle
		navigationController?.toolbar.barStyle = Themes.shared.theme[theme].barStyle
		setNeedsStatusBarAppearanceUpdate()
		UIApplication.shared.setStatusBarStyle(Themes.shared.theme[theme].statusBarStyle, animated: true)
		for themed in view.subviews {
			if let themed = themed as? Themed {
				themed.themeUpdate()
			}
		}
	}
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		let theme = UserDefaults.standard.integer(forKey: UserDefaultsKeys.themeNum)
		return Themes.shared.theme[theme].statusBarStyle
	}
	
}
