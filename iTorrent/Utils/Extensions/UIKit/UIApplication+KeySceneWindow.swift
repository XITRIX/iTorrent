//
//  UIApplication+KeySceneWindow.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 23.12.2024.
//

import UIKit

extension UIApplication {
    var keySceneWindow: UIWindow? {
        guard let keyWindow = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows
            .first(where: { $0.isKeyWindow })
        else { return nil }

        return keyWindow
    }
}
