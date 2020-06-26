//
//  ThemedUIView.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 26.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

class ThemedUIView: UIView, Themed {
    @objc func themeUpdate() { }

    override func awakeFromNib() {
        super.awakeFromNib()
        themeUpdate()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeUpdate), name: Themes.updateNotification, object: nil)
        themeUpdate()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
