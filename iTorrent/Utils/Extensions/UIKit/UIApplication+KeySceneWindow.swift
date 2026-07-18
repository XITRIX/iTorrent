//
//  UIApplication+KeySceneWindow.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 23.12.2024.
//

import UIKit

extension UIApplication {
    var keySceneWindow: UIWindow? {
        connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: { $0.isKeyWindow })
    }
}
