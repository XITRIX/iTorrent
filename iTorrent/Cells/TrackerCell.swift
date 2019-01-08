//
//  TrackerCell.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 02/07/2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class TrackerCell : ThemedUITableViewCell {
	
	@IBOutlet weak var title: UILabel!
	@IBOutlet weak var message: UILabel!
	@IBOutlet weak var seeders: UILabel!
	@IBOutlet weak var peers: UILabel!
	
	override func themeUpdate() {
		super.themeUpdate()
		let theme = UserDefaults.standard.integer(forKey: UserDefaultsKeys.themeNum)
		title?.textColor = Themes.shared.theme[theme].mainText
		message?.textColor = Themes.shared.theme[theme].secondaryText
		seeders?.textColor = Themes.shared.theme[theme].secondaryText
		peers?.textColor = Themes.shared.theme[theme].secondaryText
		
		let bgColorView = UIView()
		bgColorView.backgroundColor = Themes.shared.theme[theme].backgroundSecondary
		selectedBackgroundView = bgColorView
	}
}
