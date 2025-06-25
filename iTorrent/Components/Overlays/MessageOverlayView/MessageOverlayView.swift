//
//  MessageOverlayView.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 23.12.2024.
//

import UIKit

class MessageOverlayView: BaseView {
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var messageLabel: UILabel!

    @IBOutlet private var holder: UIControl!
    @IBOutlet private var blurView: UIVisualEffectView!

    var clickEvent: (@MainActor() async -> Void)?

    override func setup() {
        blurView.layer.cornerRadius = 20
//        blurView.layer.cornerCurve = .continuous

        holder.layer.cornerRadius = 20
//        holder.layer.cornerCurve = .continuous

        holder.layoutMargins.left = 16
        holder.layoutMargins.right = 16

        holder.layer.borderWidth = 1 / traitCollection.displayScale

        holder.addAction(.init { [unowned self] _ in
            Task { await clickEvent?() }
        }, for: .touchUpInside)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            holder.layer.borderColor = UIColor.separator.cgColor
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        holder.layer.borderColor = UIColor.separator.cgColor
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if view == self { return nil }
        return view
    }
}

extension MessageOverlayView {
    var image: UIImage? {
        get { imageView.image }
        set {
            imageView.image = newValue
            imageView.isHidden = newValue == nil
        }
    }

    var title: String? {
        get { titleLabel.text }
        set {
            titleLabel.text = newValue
            titleLabel.isHidden = newValue.isNilOrEmpty
        }
    }

    var message: String? {
        get { messageLabel.text }
        set {
            messageLabel.text = newValue
            messageLabel.isHidden = newValue.isNilOrEmpty
        }
    }
}
