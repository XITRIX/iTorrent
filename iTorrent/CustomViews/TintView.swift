//
//  TintView.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 07.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

class TintView: UIView, Themed {
    @objc func themeUpdate() {
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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        NotificationCenter.default.addObserver(self, selector: #selector(themeUpdate), name: Themes.updateNotification, object: nil)
        themeUpdate()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        themeUpdate()
    }
}
