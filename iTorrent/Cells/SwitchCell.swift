//
//  SwitchCell.swift
//  iTorrent
//
//  Created by  XITRIX on 15.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class SwitchCell: ThemedUITableViewCell {
    @IBOutlet weak var switcher: UISwitch!
    
    @IBOutlet weak var title: UILabel!
    @IBAction func valueChangedAction(_ sender: UISwitch) {
    }
	
	override func themeUpdate() {
		super.themeUpdate()
		let theme = UserDefaults.standard.integer(forKey: UserDefaultsKeys.themeNum)
		title?.textColor = Themes.shared.theme[theme].mainText
	}
}
