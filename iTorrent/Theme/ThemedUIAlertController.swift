//
//  ThemedUIAlertController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 24/06/2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class ThemedUIAlertController : UIAlertController, Themed {
	
	private struct AssociatedKeys {
		static var blurStyleKey = "UIAlertController.blurStyleKey"
	}
	
	public var blurStyle: UIBlurEffectStyle {
		get {
			return objc_getAssociatedObject(self, &AssociatedKeys.blurStyleKey) as? UIBlurEffectStyle ?? .extraLight
		} set (style) {
			objc_setAssociatedObject(self, &AssociatedKeys.blurStyleKey, style, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
			
			view.setNeedsLayout()
			view.layoutIfNeeded()
		}
	}
	
	private var visualEffectView: UIVisualEffectView? {
		if let presentationController = presentationController, presentationController.responds(to: Selector(("popoverView"))), let view = presentationController.value(forKey: "popoverView") as? UIView // We're on an iPad and visual effect view is in a different place.
		{
			return view.recursiveSubviews.compactMap({$0 as? UIVisualEffectView}).first
		}
		
		return view.recursiveSubviews.compactMap({$0 as? UIVisualEffectView}).first
	}
	
	open override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		
		visualEffectView?.effect = UIBlurEffect(style: blurStyle)
	}
	
	func updateTheme() {
		let theme = UserDefaults.standard.integer(forKey: UserDefaultsKeys.themeNum)
		
		self.blurStyle = Themes.shared.theme[theme].blurEffect
		if let cancelBackgroundViewType = NSClassFromString("_UIAlertControlleriOSActionSheetCancelBackgroundView") as? UIView.Type {
			cancelBackgroundViewType.appearance().subviewsBackgroundColor = Themes.shared.theme[theme].actionCancelButtonColor
		}
		
		if let title = title {
			let titleFont:[NSAttributedStringKey : Any] = [ .foregroundColor : preferredStyle == .alert ? Themes.shared.theme[theme].mainText : Themes.shared.theme[theme].tertiaryText ]
			let attributedTitle = NSMutableAttributedString(string: title, attributes: titleFont)
			setValue(attributedTitle, forKey: "attributedTitle")
		}
		if let message = message {
			let messageFont:[NSAttributedStringKey : Any] = [ .foregroundColor : preferredStyle == .alert ? Themes.shared.theme[theme].mainText : Themes.shared.theme[theme].tertiaryText ]
			let attributedMessage = NSMutableAttributedString(string: message, attributes: messageFont)
			setValue(attributedMessage, forKey: "attributedMessage")
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		updateTheme()
	}
}

fileprivate extension UIView {
	private struct AssociatedKey {
		static var subviewsBackgroundColor = "subviewsBackgroundColor"
	}
	
	@objc dynamic var subviewsBackgroundColor: UIColor? {
		get {
			return objc_getAssociatedObject(self, &AssociatedKey.subviewsBackgroundColor) as? UIColor
		}
		
		set {
			objc_setAssociatedObject(self,
									 &AssociatedKey.subviewsBackgroundColor,
									 newValue,
									 .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
			subviews.forEach { $0.backgroundColor = newValue }
		}
	}
}

extension UIView {
	var recursiveSubviews: [UIView] {
		var subviews = self.subviews.compactMap({$0})
		subviews.forEach { subviews.append(contentsOf: $0.recursiveSubviews) }
		return subviews
	}
}
