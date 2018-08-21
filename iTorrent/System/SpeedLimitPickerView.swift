//
//  SpeedLimitPickerView.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 03/07/2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class SpeedLimitPickerView : NSObject, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, Themed {
	
	var view: UIView!
	var pickerView: UIPickerView!
	var blurEffectView: UIVisualEffectView!
	
	weak var viewController: UIViewController!
	
	var action : (Int64)->() = {_ in}
	var dismissAction : (Int64)->() = {_ in}
	
	var dismissed = false
	
	var size : [[Int]] = []
	var sizes = ["KB/S", "MB/S"]
	
	var result : Int64 = 0
	
	init(_ viewController: UIViewController, defaultValue: Int64, onStateChange: @escaping (Int64)->(), onDismiss: @escaping (Int64)->()) {
		super.init()
		
		self.viewController = viewController
		self.action = onStateChange
		self.dismissAction = onDismiss
		result = defaultValue
		
		var kbSize : [Int] = []
		for i in 0 ... 8 {
			kbSize.append(i * 128)
		}
		
		var mbSize : [Int] = []
		for i in 0 ... 8 {
			mbSize.append(i)
		}
		
		size.append(kbSize)
		size.append(mbSize)
		
		let theme = UserDefaults.standard.integer(forKey: UserDefaultsKeys.themeNum)
		
		view = UIView(frame: CGRect(x: 0, y: viewController.view.frame.size.height, width: viewController.view.frame.size.width, height: 216))
		view.clipsToBounds = true
		view.layer.cornerRadius = 10
		if #available(iOS 11.0, *) {
			view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
		}
		
		pickerView = UIPickerView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 216))
		pickerView.delegate = self
		pickerView.dataSource = self
		pickerView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0)
		pickerView.tintColor = Themes.shared.theme[theme].tableHeaderColor
		
		let blurEffect = UIBlurEffect(style: Themes.shared.theme[theme].blurEffect)
		blurEffectView = UIVisualEffectView(effect: blurEffect)
		blurEffectView.frame = view.bounds
		blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		
		let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 44))
		toolBar.barStyle = Themes.shared.theme[theme].barStyle
		toolBar.isTranslucent = true
		toolBar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
		toolBar.setShadowImage(UIImage(), forToolbarPosition: .any)
		toolBar.tintColor = viewController.navigationController?.navigationBar.tintColor
		
		// Adding Button ToolBar
		let doneButton = UIBarButtonItem(title: NSLocalizedString("Done", comment: ""), style: .done, target: self, action: #selector(SpeedLimitPickerView.doneClick))
		let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
		//let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(SeedLimitPicker.cancelClick))
		toolBar.setItems([spaceButton, doneButton], animated: false)
		toolBar.isUserInteractionEnabled = true
		
		view.addSubview(blurEffectView)
		view.addSubview(pickerView)
		view.addSubview(toolBar)
		
		viewController.navigationController?.view.addSubview(view)
		UIView.animate(withDuration: 0.3) {
			self.view.frame.origin.y -= 216
		}
		
		let def = defaultValue / 1024
		if def > 1024 {
			pickerView.selectRow(1, inComponent: 1, animated: true)
			pickerView.selectRow(Int(def/1024), inComponent: 0, animated: true)
		} else {
			pickerView.selectRow(0, inComponent: 1, animated: true)
			pickerView.selectRow(Int(def/128), inComponent: 0, animated: true)
		}
	}
	
	func updateTheme() {
		let theme = UserDefaults.standard.integer(forKey: UserDefaultsKeys.themeNum)
		blurEffectView.effect = UIBlurEffect(style: Themes.shared.theme[theme].blurEffect)
		pickerView.reloadAllComponents()
	}
	
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 2
	}
	
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		if (component == 0) {
			if (pickerView.numberOfComponents > 1 && pickerView.numberOfRows(inComponent: 1) > 1 && pickerView.selectedRow(inComponent: 1) == 1) {
				return size[1].count
			}
			return size[0].count
		}
		return sizes.count
	}
	
	func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
		let theme = UserDefaults.standard.integer(forKey: UserDefaultsKeys.themeNum)
		let titleFont:[NSAttributedStringKey : Any] = [ .foregroundColor : Themes.shared.theme[theme].mainText ]
		if (component == 0 && row == 0) {
			return NSAttributedString(string: NSLocalizedString("Unlimited", comment: ""), attributes: titleFont)
		}
		if (component == 0) {
			if (pickerView.numberOfComponents > 1 && pickerView.numberOfRows(inComponent: 1) > 1 && pickerView.selectedRow(inComponent: 1) == 1) {
				return NSAttributedString(string: String(size[1][row]), attributes: titleFont)
			}
			return NSAttributedString(string: String(size[0][row]), attributes: titleFont)
		}
		return NSAttributedString(string: sizes[row], attributes: titleFont)
	}
	
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		if (component == 1) {
			pickerView.reloadComponent(0)
		}
		let cmp0 = pickerView.selectedRow(inComponent: 0)
		let cmp1 = pickerView.selectedRow(inComponent: 1)
		if (cmp1 == 0) {
			result = Int64(size[cmp1][cmp0]) * 1024
		} else {
			result = Int64(size[cmp1][cmp0]) * 1048576
		}
		action(result)
	}
	
	func dismiss() {
		if (!dismissed) {
			dismissed = true
			dismissAction(result)
			UIView.animate(withDuration: 0.3, animations: {
				self.view.frame.origin.y += 216
			}) { _ in
				self.view.removeFromSuperview()
			}
		}
	}
	
	@objc func doneClick() {
		dismiss()
	}
	
}

