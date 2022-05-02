//
//  UIWindow+Key.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 02.05.2022.
//

import UIKit

extension UIWindow {
    static var keyWindow: UIWindow? {
        UIApplication
            .shared
            .connectedScenes
            .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
            .first { $0.isKeyWindow }
    }
}
