//
//  MarqueeLabel+Reactive.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 27.04.2022.
//

import Bond
import MarqueeLabel
import ReactiveKit

public extension ReactiveExtensions where Base: MarqueeLabel {
    var text: Bond<String?> {
        return bond { $0.text = $1 }
    }

    var attributedText: Bond<NSAttributedString?> {
        return bond { $0.attributedText = $1 }
    }

    var textColor: Bond<UIColor?> {
        return bond { $0.textColor = $1 }
    }
}
