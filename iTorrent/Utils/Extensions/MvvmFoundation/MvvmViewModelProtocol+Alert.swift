//
//  MvvmViewModelProtocol+Alert.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 07.04.2024.
//

import MvvmFoundation
import UIKit

extension MvvmViewModelProtocol {
    @available(visionOS, unavailable)
    func textMultilineInput(title: String?,
                            message: String? = nil,
                            placeholder: String? = nil,
                            defaultValue: String? = nil,
                            textViewConfiguration: ((EditTextView) -> Void)? = nil,
                            type: UIKeyboardType = .default,
                            cancel: String = %"common.cancel",
                            accept: String,
                            result: @escaping (String?) -> Void)
    {
        let dialog = UIAlertController(title: title,
                                       message: message,
                                       preferredStyle: .alert)

        let editTextView = EditTextView()
        let editTextController = EditTextViewController(editTextView: editTextView)

        editTextView.keyboardType = type
        editTextView.placeholder = placeholder
        editTextView.text = defaultValue
        
        textViewConfiguration?(editTextView)
        dialog.setValue(editTextController, forKey: "contentViewController")

        let cancel = UIAlertAction(title: cancel, style: .cancel) { _ in
            result(nil)
        }
        let ok = UIAlertAction(title: accept, style: .default) { _ in
            result(editTextView.text)
        }

        dialog.addAction(cancel)
        dialog.addAction(ok)

        DispatchQueue.main.async {
            editTextView.becomeFirstResponder()
        }

        editTextView.layer.borderColor = UIColor.systemRed.withAlphaComponent(0.1).cgColor
        navigationService?()?.present(dialog, animated: true)
    }
}
