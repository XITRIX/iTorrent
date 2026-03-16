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

        textView.font = UIFont.systemFont(ofSize: UIFont.systemFontSize * 1.0)

        textView.layer.isOpaque = false
        textView.layer.backgroundColor = nil
        textView.returnKeyType = .default
        textView.autocapitalizationType = .none
       
        textView.translatesAutoresizingMaskIntoConstraints = false

        textView.textContainerInset = .zero
        if #available(iOS 26, *) {
            textView.layer.cornerRadius = 25

            textView.contentInset.top =     16 // For top padding
            textView.contentInset.bottom =  16 // For bottom padding

            textView.textContainerInset.left =    12 // For left padding
            textView.textContainerInset.right =   12 // For right padding
            textView.textContainerInset.top =     0 // For top padding
            textView.textContainerInset.bottom =  0 // For bottom padding
        } else {
            textView.layer.cornerRadius = 8

            textView.contentInset.top =     8 // For top padding
            textView.contentInset.bottom =  8 // For bottom padding

            textView.textContainerInset.left =    2 // For left padding
            textView.textContainerInset.right =   2 // For right padding
            textView.textContainerInset.top =     0 // For top padding
            textView.textContainerInset.bottom =  0 // For bottom padding

            textView.borderColor = UIColor.lightGray.withAlphaComponent(0.5)
        }
        
        setupPlaceholderLabel()
    }
    
    private func setupPlaceholderLabel() {
        addSubview(placeholderLabel)

        placeholderLabel.font = UIFont.systemFont(ofSize: UIFont.systemFontSize * 1.0)
//        placeholderLabel.layer.borderColor = UIColor.systemRed.cgColor

        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        // Set constraints for the placeholder label
        NSLayoutConstraint.activate([
            placeholderLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: textContainerInset.left+4),
            placeholderLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -(textContainerInset.right+4)),
            placeholderLabel.topAnchor.constraint(equalTo: topAnchor, constant: textContainerInset.top),
            placeholderLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -(textContainerInset.bottom))
        ])
        
        // Hide the placeholder label when there is text
        NotificationCenter.default.addObserver(self, selector: #selector(textDidChange), name: UITextView.textDidChangeNotification, object: nil)
    }
    
    @objc private func textDidChange() {
        placeholderLabel.isHidden = !text.isEmpty
    }
}
