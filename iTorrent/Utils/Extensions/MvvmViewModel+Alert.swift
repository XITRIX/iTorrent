//
//  MvvmViewModel+Alert.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 08/11/2023.
//

import MvvmFoundation
import UIKit

extension MvvmViewModelProtocol {
    func textInput(title: String?, message: String? = nil, placeholder: String?, defaultValue: String?, type: UIKeyboardType, result: @escaping (String?) -> Void) {
        textInput(title: title, message: message, placeholder: placeholder, defaultValue: defaultValue, type: type, cancel: String(localized: "common.cancel"), accept: String(localized: "common.ok"), result: result)
    }
}
