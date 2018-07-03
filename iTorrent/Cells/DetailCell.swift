//
//  CellDetail.swift
//  iTorrent
//
//  Created by  XITRIX on 15.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class DetailCell: ThemedUITableViewCell {
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var details: UILabel!
	
	override func updateTheme() {
		super.updateTheme()
		let theme = UserDefaults.standard.integer(forKey: UserDefaultsKeys.themeNum)
		if (title != nil) {
			title.textColor = Themes.shared.theme[theme].mainText
		}
		if (details != nil) {
			details.textColor = Themes.shared.theme[theme].selectedText
		}
	}
}
