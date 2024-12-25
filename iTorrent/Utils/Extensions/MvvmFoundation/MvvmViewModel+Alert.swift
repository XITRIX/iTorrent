//
//  MvvmViewModel+Alert.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 08/11/2023.
//

import MvvmFoundation
import UIKit

extension MvvmViewModelProtocol {
    @MainActor
    func textInput(title: String?, message: String? = nil, placeholder: String?, defaultValue: String? = nil, type: UIKeyboardType = .default, secured: Bool = false, accept: String = String(localized: "common.ok"), result: @escaping (String?) -> Void) {
        textInput(title: title, message: message, placeholder: placeholder, defaultValue: defaultValue, type: type, secured: secured, cancel: String(localized: "common.cancel"), accept: accept, result: result)
    }

    @MainActor
    func textInputs(title: String?, message: String? = nil, textInputs: [MvvmTextInputModel], accept: String = String(localized: "common.ok"), result: @escaping ([String]?) -> Void) {
        self.textInputs(title: title, message: message, textInputs: textInputs, cancel: String(localized: "common.cancel"), accept: accept, result: result)
    }
}
