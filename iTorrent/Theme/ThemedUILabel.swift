//
//  ThemedUILabel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 24/06/2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class ThemedUILabel: UILabel, Themed {
    @available(*, unavailable, message: "This property is reserved for Interface Builder. Use 'secondaryColor' instead.")
    @IBInspectable var colorTypeAdapter: Int {
        get {
            return colorType.rawValue
        }
        set {
            if let newColorType = TextType(rawValue: newValue) {
                colorType = newColorType
            }
        }
    }

    var colorType: TextType = .primary

    override init(frame: CGRect) {
        super.init(frame: frame)
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

    @objc func themeUpdate() {
        let theme = Themes.current
        switch colorType {
        case .primary:
            textColor = theme.mainText
        case .secondary:
            textColor = theme.secondaryText
        case .tetriary:
            textColor = theme.tertiaryText
        }
    }

    enum TextType: Int {
        case primary
        case secondary
        case tetriary
    }
}
