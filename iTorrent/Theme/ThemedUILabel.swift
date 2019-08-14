//
//  ThemedUILabel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 24/06/2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class ThemedUILabel : UILabel, Themed {
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        NotificationCenter.default.addObserver(self, selector: #selector(themeUpdate), name: Themes.updateNotification, object: nil)
        themeUpdate()
    }
    
    @objc func themeUpdate() {
		textColor = Themes.current().mainText
	}
}
