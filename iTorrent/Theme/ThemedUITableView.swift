//
//  ThemedUITableView.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 24/06/2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class ThemedUITableView: UITableView, Themed {
    @available(*, unavailable, message: "This property is reserved for Interface Builder. Use 'colorType' instead.")
    @IBInspectable var colorTypeAdapter: Int {
        get {
            return colorType.rawValue
        }
        set {
            if let newColorType = ColorType(rawValue: newValue) {
                colorType = newColorType
            }
        }
    }

    var colorType: ColorType = .primary {
        didSet {
            themeUpdate()
        }
    }

    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func setup() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeUpdate), name: Themes.updateNotification, object: nil)
        themeUpdate()
    }

    @objc func themeUpdate() {
        let theme = Themes.current
        tintColor = theme.tintColor
        
        switch colorType {
        case .primary:
            backgroundColor = theme.backgroundMain
        case .secondary:
            backgroundColor = theme.backgroundSecondary
        }
    }

    enum ColorType: Int {
        case primary
        case secondary
    }
}
