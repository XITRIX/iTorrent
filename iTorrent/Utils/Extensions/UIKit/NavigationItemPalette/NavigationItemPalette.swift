//
//  NavigationItemPalette.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 14.11.2024.
//

import UIKit

extension UIView {
}

extension UINavigationItem {
    func setBottomPalette(_ contentView: UIView?, height: CGFloat = 44) {
        /// "_setBottomPalette:"
        let selector = NSSelectorFromBase64String("X3NldEJvdHRvbVBhbGV0dGU6")
        guard responds(to: selector) else { return }
        perform(selector, with: Self.makeNavigationItemPalette(with: contentView, height: height))
    }

    private static func makeNavigationItemPalette(with contentView: UIView?, height: CGFloat) -> UIView? {
        guard let contentView else { return nil }
        contentView.translatesAutoresizingMaskIntoConstraints = false

        let contentViewHolder = UIView(frame: .init(x: 0, y: 0, width: 0, height: height))
        contentViewHolder.autoresizingMask = [.flexibleHeight]
        contentViewHolder.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentViewHolder.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentViewHolder.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentView.trailingAnchor.constraint(equalTo: contentViewHolder.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: contentViewHolder.bottomAnchor),
        ])

        /// "_UINavigationBarPalette"
        guard let paletteClass = NSClassFromBase64String("X1VJTmF2aWdhdGlvbkJhclBhbGV0dGU=") as? UIView.Type
        else { return nil }

        /// "alloc"
        /// "initWithContentView:"
        guard let palette = paletteClass.perform(NSSelectorFromBase64String("YWxsb2M="))
            .takeUnretainedValue()
            .perform(NSSelectorFromBase64String("aW5pdFdpdGhDb250ZW50Vmlldzo="), with: contentViewHolder)
            .takeUnretainedValue() as? UIView
        else { return nil }

        palette.preservesSuperviewLayoutMargins = true
        return palette
    }
}

func NSSelectorFromBase64String(_ base64String: String) -> Selector {
    NSSelectorFromString(String(base64: base64String))
}

func NSClassFromBase64String(_ aBase64ClassName: String) -> AnyClass? {
    NSClassFromString(String(base64: aBase64ClassName))
}

extension String {
    init(base64: String) {
        self.init(data: Data(base64Encoded: base64)!, encoding: .utf8)!
    }
}
