//
//  TintView.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 07.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

class TintView: ThemedUIView {
    override func themeUpdate() {
        super.themeUpdate()
        tintColor = Themes.current.tintColor
        setNeedsDisplay()
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(tintColor.cgColor)
        context?.fill(rect)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
