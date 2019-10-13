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
    
    @IBOutlet weak var title: ThemedUILabel!
    @IBOutlet weak var details: UILabel!
	
	override func themeUpdate() {
		super.themeUpdate()
        
		let theme = Themes.current
        details?.textColor = theme.selectedText
	}
}
