//
//  EditTextViewController.swift
//  iTorrent
//
//  Created by Magesh K on 17.10.2023.
//  Copyright © 2023  Magesh K. All rights reserved.
//

import Foundation
import UIKit

class EditTextViewController: UIViewController, UITextViewDelegate {
    private let editTextView: EditTextView
    private var SINGLE_LINE_HEIGHT: Double {
        if #available(iOS 26.0, *) {
            54
        } else {
            36
        }
    }

    convenience init() {
        self.init(editTextView: EditTextView())
    }

    init(editTextView: EditTextView) {
        self.editTextView = editTextView
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.editTextView = EditTextView()
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // add the UITextView
        editTextView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(editTextView)

        view.preservesSuperviewLayoutMargins = true

        NSLayoutConstraint.activate([
            view.layoutMarginsGuide.leadingAnchor.constraint(equalTo: editTextView.leadingAnchor),
            view.topAnchor.constraint(equalTo: editTextView.topAnchor, constant: -2),
            view.layoutMarginsGuide.trailingAnchor.constraint(equalTo: editTextView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: editTextView.bottomAnchor, constant: 2),
        ])

        // register callback for textView changes
        editTextView.delegate = self
        // Create a height constraint for the view controller's view
        viewControllerHeightConstraint = view.heightAnchor.constraint(equalToConstant: SINGLE_LINE_HEIGHT)
        viewControllerHeightConstraint.isActive = true
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)

        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
    }

    var viewControllerHeightConstraint: NSLayoutConstraint!
    
    func textViewDidChange(_ textView: UITextView) {
        let maxLinesToShow = 4.0
        let maxContentSize: Double = SINGLE_LINE_HEIGHT * maxLinesToShow
        
        var contentSize: Double = textView.contentSize.height + 17.0
        if contentSize > maxContentSize {
            contentSize = maxContentSize
        }
        if contentSize < SINGLE_LINE_HEIGHT {
            contentSize = SINGLE_LINE_HEIGHT
        }
        
        if contentSize != prevContentSize {
            // Calculate the content height of the UITextView
            // Update the height constraint of the view controller's view
            viewControllerHeightConstraint.constant = contentSize

            // Optionally, animate the constraint change
            UIView.animate(
                withDuration: 0.5,
                delay: 0.0,
                usingSpringWithDamping: 0.5, // Adjust this value (lower for more bounce, higher for less)
                initialSpringVelocity: 0.0, // Adjust this value (higher for more initial velocity)
                options: [.curveEaseInOut], // Use curveEaseInOut
                animations: {
                    self.view.layoutIfNeeded()
                },
                completion: nil
            )
        }
        prevContentSize = contentSize
        
        // Optionally, you can scroll to the bottom as the user types
//        let bottomOffset = CGPoint(x: 0, y: max(textView.contentSize.height - textView.bounds.size.height, 0))
//        textView.setContentOffset(bottomOffset, animated: false)
    }
    
    private var prevContentSize: Double = 0.0
}
