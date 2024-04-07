//
//  EditTextViewController.swift
//  iTorrent
//
//  Created by Magesh K on 17.10.2023.
//  Copyright © 2023  Magesh K. All rights reserved.
//

import Foundation
import UIKit

// EditTextView - UI Control
class EditTextView: UITextView {
    // Set margins using UIEdgeInsets
    let defaultMargins = UIEdgeInsets(top: 4, left: 12, bottom: 12, right: 12)
    
    // Custom placeholder text
    var placeholder: String? {
        didSet { placeholderLabel.text = placeholder }
    }
    
    // Custom placeholder text color
    var placeholderTextColor: UIColor = .lightGray {
        didSet { placeholderLabel.textColor = placeholderTextColor }
    }
    
    // Private UILabel for the placeholder text
    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        return label
    }()

    /* Override methods */
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        performCustomizations()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        performCustomizations()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        layer.borderWidth = 1 / traitCollection.displayScale
    }

    /* Helper methods */
    private func performCustomizations() {
        let textView = self
        
        textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        textView.font = UIFont.systemFont(ofSize: UIFont.systemFontSize * 1.0)
        textView.contentInset.left =    2 // For left padding
        textView.contentInset.right =   2 // For right padding
        textView.contentInset.top =     2 // For top padding
        textView.contentInset.bottom =  2 // For bottom padding

        textView.layer.isOpaque = false
        textView.layer.cornerRadius = 8
        textView.borderColor = UIColor.lightGray.withAlphaComponent(0.5)
        textView.layer.backgroundColor = nil
        textView.returnKeyType = .default
        textView.autocapitalizationType = .none
       
        textView.translatesAutoresizingMaskIntoConstraints = false
        setupPlaceholderLabel()
    }
    
    private func setupPlaceholderLabel() {
        addSubview(placeholderLabel)

        placeholderLabel.font = UIFont.systemFont(ofSize: UIFont.systemFontSize * 1.0)
//        placeholderLabel.layer.borderColor = UIColor.systemRed.cgColor

        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        // Set constraints for the placeholder label
        NSLayoutConstraint.activate([
            placeholderLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: contentInset.left+4),
            placeholderLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -(contentInset.right+4)),
            placeholderLabel.topAnchor.constraint(equalTo: topAnchor, constant: contentInset.top+6),
            placeholderLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -(contentInset.bottom+6))
        ])
        
        // Hide the placeholder label when there is text
        NotificationCenter.default.addObserver(self, selector: #selector(textDidChange), name: UITextView.textDidChangeNotification, object: nil)
    }
    
    @objc private func textDidChange() {
        placeholderLabel.isHidden = !text.isEmpty
    }
    
    public func setDefaultMargins() {
        setMargins(by: defaultMargins)
    }
    
    public func setMargins(by: UIEdgeInsets) {
        let margins = by
        if let containerView = superview {
            frame = containerView.frame
            // Add constraints to the UITextView within the parent view
            NSLayoutConstraint.activate([
                leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: margins.left),
                trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -margins.right),
                topAnchor.constraint(equalTo: containerView.topAnchor, constant: margins.top),
                bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -margins.bottom)
            ])
        }
    }
    
    // callback for superview changes
    override func didMoveToSuperview() {
        // attach superView's frame reference into this view
        // and set margins if superView is present
        setDefaultMargins()
    }
}
