//
//  ThemedUITableViewCell.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 24/06/2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class ThemedUITableViewCell : UITableViewCell, Themed {
	
	func updateTheme() {
		let theme = UserDefaults.standard.integer(forKey: UserDefaultsKeys.themeNum)
		
		textLabel?.textColor = Themes.shared.theme[theme].mainText
		backgroundColor = Themes.shared.theme[theme].backgroundMain
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		updateTheme()
	}
	
	override func prepareForInterfaceBuilder() {
		super.prepareForInterfaceBuilder()
		updateTheme()
	}
	
}
