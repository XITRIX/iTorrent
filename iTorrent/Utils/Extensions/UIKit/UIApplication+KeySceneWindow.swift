//
//  UIApplication+KeySceneWindow.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 23.12.2024.
//

import UIKit

extension UIApplication {
    var keySceneWindow: UIWindow {
        guard let keyWindow = UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows
            .first(where: { $0.isKeyWindow })
        else { fatalError("It should not be possible to not have keyWindow") }

        return keyWindow
    }
}
