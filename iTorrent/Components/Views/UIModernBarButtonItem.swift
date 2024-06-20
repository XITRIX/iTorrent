//
//  UIModernBarButtonItem.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 06.05.2024.
//

import UIKit

class UIModernBarButtonItem: UIBarButtonItem {
    override var image: UIImage? {
        get { super.image }
        set {
#if os(iOS)
            super.image = newValue?.withConfiguration(UIImage.SymbolConfiguration(textStyle: .body, scale: .large)).withConfiguration(UIImage.SymbolConfiguration(pointSize: 15, weight: .bold, scale: .medium))
#else
            super.image = newValue
#endif
        }
    }

    override init() {
        super.init()
    }

    init(image: UIImage? = nil) {
        super.init()
        self.image = image

#if os(iOS)
        let image = UIImage(systemName: "circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30))?.withTintColor(PreferencesStorage.shared.tintColor.withAlphaComponent(0.25), renderingMode: .alwaysOriginal)
        setBackgroundImage(image, for: .normal, barMetrics: .default)
#endif
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

#if os(iOS)
        let image = UIImage(systemName: "circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30))?.withTintColor(.tertiarySystemFill, renderingMode: .alwaysOriginal)
        setBackgroundImage(image, for: .normal, barMetrics: .default)
#endif
    }
}
