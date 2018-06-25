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
	
	func updateTheme() {
		let theme = UserDefaults.standard.integer(forKey: UserDefaultsKeys.themeNum)
		
		if let cancelBackgroundViewType = NSClassFromString("_UIAlertControlleriOSActionSheetCancelBackgroundView") as? UIView.Type {
			cancelBackgroundViewType.appearance().subviewsBackgroundColor = Themes.shared.theme[theme].backgroundSecondary
		}
		
		for v in view.searchVisualEffectsSubview() {
			v.effect = UIBlurEffect(style: Themes.shared.theme[theme].blurEffect)
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
	func searchVisualEffectsSubview() -> [UIVisualEffectView] {
		if let visualEffectView = self as? UIVisualEffectView {
			return [visualEffectView]
		} else {
			var list : [UIVisualEffectView] = []
			for subview in subviews {
				list.append(contentsOf: subview.searchVisualEffectsSubview())
			}
			return list
		}
	}
}
