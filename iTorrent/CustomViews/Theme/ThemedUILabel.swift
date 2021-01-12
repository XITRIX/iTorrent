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
    @available(*, unavailable, message: "This property is reserved for Interface Builder. Use 'colorType' instead.")
    @IBInspectable var colorTypeAdapter: Int {
        get {
            colorType.rawValue
        }
        set {
            if let newColorType = TextType(rawValue: newValue) {
                colorType = newColorType
            }
        }
    }

    var colorType: TextType = .primary {
        didSet {
            themeUpdate()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    func setup() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeUpdate), name: Themes.updateNotification, object: nil)
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
