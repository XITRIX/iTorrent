//
//  ButtonCell.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 25/06/2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class ButtonCell : ThemedUITableViewCell {
	@IBOutlet weak var title: ThemedUILabel!
	@IBOutlet weak var button: UIButton!
	
	override func themeUpdate() {
		super.themeUpdate()
		let theme = UserDefaults.standard.integer(forKey: UserDefaultsKeys.themeNum)
        title?.textColor = Themes.shared.theme[theme].mainText
		button?.titleLabel?.textColor = Themes.shared.theme[theme].selectedText
	}
}
