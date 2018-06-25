//
//  ThemedUITableView.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 24/06/2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class ThemedUITableView : UITableView, Themed {
	
	func updateTheme() {
		let theme = UserDefaults.standard.integer(forKey: UserDefaultsKeys.themeNum)
		backgroundColor = Themes.shared.theme[theme].backgroundTertiary
		reloadData()
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
