//
//  UpdatesDialog.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 21/08/2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class Dialog {
    static func withTimer(_ presenter: UIViewController?, title: String? = nil, message: String? = nil) {
        let alert = ThemedUIAlertController(title: Localize.get(key: title), message: Localize.get(key: message), preferredStyle: .alert)
        presenter?.present(alert, animated: true, completion: nil)
        // change alert timer to 2 seconds, then dismiss
        let when = DispatchTime.now() + 2
        DispatchQueue.main.asyncAfter(deadline: when) {
            alert.dismiss(animated: true, completion: nil)
        }
    }
    
    static func withTextField(_ presenter: UIViewController?, title: String? = nil, message: String? = nil, textFieldConfiguration: ((UITextField) -> ())?, cancelText: String = "Close", okText: String = "OK", okAction: @escaping (UITextField) -> ()) {
        let dialog = ThemedUIAlertController(title: Localize.get(key: title), message: Localize.get(key: message), preferredStyle: .alert)
        dialog.addTextField { textField in
            let theme = Themes.current
            textField.keyboardAppearance = theme.keyboardAppearence
            textFieldConfiguration?(textField)
        }
        
        let cancel = UIAlertAction(title: Localize.get(cancelText), style: .cancel)
        let ok = UIAlertAction(title: Localize.get(okText), style: .default) { _ in
            okAction(dialog.textFields![0])
        }
        
        dialog.addAction(cancel)
        dialog.addAction(ok)
        
        presenter?.present(dialog, animated: true)
    }
    
    static func withTextView(_ presenter: UIViewController?,
                               title: String? = nil,
                               message: String? = nil,
                               textViewConfiguration: ((EditTextView) -> ())?,
                               cancelText: String = "Close",
                               okText: String = "OK",
                               okAction: @escaping (EditTextView) -> ()) {
        
        let dialog = ThemedUIAlertController(title: Localize.get(key: title), 
                                             message: Localize.get(key: message),
                                             preferredStyle: .alert)

        let editTextView = EditTextView()
        let editTextController = EditTextViewController(editTextView: editTextView)
        
        textViewConfiguration!(editTextView)
        dialog.setValue(editTextController, forKey: "contentViewController")
        
        let cancel = UIAlertAction(title: Localize.get(cancelText), style: .cancel)
        let ok = UIAlertAction(title: Localize.get(okText), style: .default) { _ in
            okAction(editTextView)
        }
        
        dialog.addAction(cancel)
        dialog.addAction(ok)
        
        presenter?.present(dialog, animated: true)
    }
    
    static func withButton(_ presenter: UIViewController? = Utils.topViewController, title: String? = nil, message: String? = nil, okTitle: String, action: @escaping ()->()) {
        let dialog = ThemedUIAlertController(title: Localize.get(key: title),
                                             message: Localize.get(key: message),
                                             preferredStyle: .alert)
        
        let cancel = UIAlertAction(title: Localize.get("Cancel"), style: .cancel)
        let ok = UIAlertAction(title: Localize.get(okTitle), style: .default) { _ in
            action()
        }
        
        dialog.addAction(cancel)
        dialog.addAction(ok)
        
        presenter?.present(dialog, animated: true)
    }
    
    static func show(_ presenter: UIViewController? = Utils.topViewController, title: String?, message: String?, closeText: String = "Close") {
        let dialog = ThemedUIAlertController(title: Localize.get(key: title), message: Localize.get(key: message), preferredStyle: .alert)
        let ok = UIAlertAction(title: Localize.get(closeText), style: .cancel)
        dialog.addAction(ok)
        presenter?.present(dialog, animated: true)
    }
    
    static func createUpdateLogs(forced: Bool = false, closeAction: (() -> ())? = nil) -> ThemedUIAlertController? {
        let localUrl = Bundle.main.url(forResource: "Version", withExtension: "ver")
        if let localVersion = try? String(contentsOf: localUrl!) {
            if !UserPreferences.versionNews || forced {
                let title = localVersion + NSLocalizedString("info", comment: "")
                let newsController = ThemedUIAlertController(title: title.replacingOccurrences(of: "\n", with: ""), message: "UpdateText".localized, preferredStyle: .alert)
                let close = UIAlertAction(title: Localize.get("Close"), style: .cancel) { _ in
                    UserPreferences.versionNews = true
                    closeAction?()
                }
                newsController.addAction(close)
                return newsController
            }
        }
        closeAction?()
        return nil
    }
}


// EditTextView - UI Control
class EditTextView: UITextView{
    
    // Set margins using UIEdgeInsets
    let defaultMargins      = UIEdgeInsets(top: 4, left: 12, bottom: 12, right: 12)
    let defaultPlaceholder  = NSLocalizedString("PlaceHolder text", comment: "")
    
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
    override init(frame: CGRect, textContainer: NSTextContainer?){
        super.init(frame: frame, textContainer:textContainer)
        performCustomizations()
    }
    
    required init?(coder: NSCoder){
        super.init(coder:coder)
        performCustomizations()
    }
    
    
    /* Helper methods */
    private func performCustomizations() -> Void{
        let textView = self
        let theme = Themes.current
        
        textView.keyboardAppearance = theme.keyboardAppearence
        textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        textView.font = UIFont.systemFont(ofSize: UIFont.systemFontSize * 1.0)
        textView.contentInset.left      = 2         //For left padding
        textView.contentInset.right     = 2         //For right padding
        textView.contentInset.top       = 2         //For top padding
        textView.contentInset.bottom    = 2         //For bottom padding
        
        textView.layer.borderWidth = 0.5
        textView.layer.cornerRadius = 8
        textView.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
        textView.layer.backgroundColor = nil
        textView.returnKeyType = .default
        textView.autocapitalizationType = .none
       
        textView.translatesAutoresizingMaskIntoConstraints = false
        setupPlaceholderLabel()
    }
    
    private func setupPlaceholderLabel() {
        addSubview(placeholderLabel)
        
        placeholder = self.defaultPlaceholder
        placeholderLabel.font = UIFont.systemFont(ofSize: UIFont.systemFontSize * 1.0)
        placeholderLabel.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor

        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        // Set constraints for the placeholder label
        NSLayoutConstraint.activate([
            placeholderLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: self.contentInset.left+4),
            placeholderLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -(self.contentInset.right+4)),
            placeholderLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: self.contentInset.top+6),
            placeholderLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -(self.contentInset.bottom+6))
        ])
        
        // Hide the placeholder label when there is text
        NotificationCenter.default.addObserver(self, selector: #selector(textDidChange), name: UITextView.textDidChangeNotification, object: nil)
    }
    
    @objc private func textDidChange() {
        placeholderLabel.isHidden = !text.isEmpty
    }
    
    public func setDefaultMargins(){
        setMargins(by: self.defaultMargins)
    }
    
    
    public func setMargins(by: UIEdgeInsets){
        let margins = by
        if let containerView = self.superview{
            self.frame = containerView.frame
            // Add constraints to the UITextView within the parent view
            NSLayoutConstraint.activate([
                self.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: margins.left),
                self.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -margins.right),
                self.topAnchor.constraint(equalTo: containerView.topAnchor, constant: margins.top),
                self.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -margins.bottom)
            ])
        }
    }
    
    // callback for superview changes
    override func didMoveToSuperview() {
        // attach superView's frame reference into this view
        // and set margins if superView is present
        self.setDefaultMargins()
    }
}


class EditTextViewController: UIViewController, UITextViewDelegate {
    
    private let editTextView:EditTextView
    private let SINGLE_LINE_HEIGHT:Double = 54.0

    convenience init(){
        self.init(editTextView: EditTextView())
    }

    init(editTextView: EditTextView){
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
        self.view.addSubview(self.editTextView)
        // register callback for textView changes
        editTextView.delegate = self
        // Create a height constraint for the view controller's view
        viewControllerHeightConstraint = view.heightAnchor.constraint(equalToConstant: SINGLE_LINE_HEIGHT)
        viewControllerHeightConstraint.isActive = true
    }
    
    var viewControllerHeightConstraint: NSLayoutConstraint!
    
    func textViewDidChange(_ textView: UITextView) {

        let maxLinesToShow:Double = 1.5
        let maxContentSize:Double = SINGLE_LINE_HEIGHT * maxLinesToShow
        
        var contentSize:Double = textView.contentSize.height + 17.0
        if contentSize > maxContentSize{
            contentSize = maxContentSize
        }
        if contentSize < SINGLE_LINE_HEIGHT{
            contentSize = SINGLE_LINE_HEIGHT
        }
        
        if(contentSize != prevContentSize){
            // Calculate the content height of the UITextView
            // Update the height constraint of the view controller's view
            viewControllerHeightConstraint.constant = contentSize

            // Optionally, animate the constraint change
            UIView.animate(
                       withDuration: 0.5,
                       delay: 0.0,
                       usingSpringWithDamping: 0.5, // Adjust this value (lower for more bounce, higher for less)
                       initialSpringVelocity: 0.0,  //Adjust this value (higher for more initial velocity)
                       options: [.curveEaseInOut],  // Use curveEaseInOut
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
