//
//  ColorPalett.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 24/06/2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class Themes {
	
	static let shared = Themes()
	
	var theme : [ColorPalett] = []
	
	private init() {
		let darkTheme = ColorPalett()
		
		darkTheme.mainText = UIColor.white
		darkTheme.secondaryText = UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1)
		darkTheme.tertiaryText = UIColor(red: 115/255, green: 115/255, blue: 115/255, alpha: 1)
		darkTheme.selectedText = UIColor(red: 255/255, green: 255/255, blue: 120/255, alpha: 1)
		darkTheme.backgroundMain = UIColor.black
		darkTheme.backgroundSecondary = UIColor(red: 55/255, green: 55/255, blue: 55/255, alpha: 1)
		darkTheme.backgroundTertiary = UIColor(red: 55/255, green: 55/255, blue: 55/255, alpha: 1)
		darkTheme.tableHeaderColor = UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 0.9)
		darkTheme.actionCancelButtonColor = UIColor(red: 28.0/255.0, green: 28.0/255.0, blue: 28.0/255.0, alpha: 1.0)
		darkTheme.statusBarStyle = .lightContent
		darkTheme.barStyle = .black
		darkTheme.blurEffect = .dark
		darkTheme.keyboardAppearence = .dark
		darkTheme.loadingIndicatorStyle = .white
		
		theme.append(ColorPalett())
		theme.append(darkTheme)
	}
	
	static func current() -> ColorPalett {
		return shared.theme[UserDefaults.standard.integer(forKey: UserDefaultsKeys.themeNum)]
	}
	
}

class ColorPalett {
	var mainText = UIColor.black
	var secondaryText = UIColor(red: 85/255, green: 85/255, blue: 85/255, alpha: 1)
	var tertiaryText = UIColor(red: 140/255, green: 140/255, blue: 140/255, alpha: 1)
	var selectedText = UIColor(red: 0/255, green: 0/255, blue: 135/255, alpha: 1)
	var backgroundMain = UIColor.white
	var backgroundSecondary = UIColor(red: 239/255, green: 239/255, blue: 244/255, alpha: 1)
	var backgroundTertiary = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1)
	var tableHeaderColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 0.9)
	var actionCancelButtonColor = UIColor(red: 239/255, green: 239/255, blue: 244/255, alpha: 1)
	var statusBarStyle : UIStatusBarStyle = .default
	var barStyle : UIBarStyle = .default
	var blurEffect : UIBlurEffect.Style = .light
	var keyboardAppearence : UIKeyboardAppearance = .default
	var loadingIndicatorStyle : UIActivityIndicatorViewStyle = .gray
}
