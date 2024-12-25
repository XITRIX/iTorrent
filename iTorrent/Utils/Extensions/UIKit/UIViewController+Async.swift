//
//  UIViewController+Async.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 25.12.2024.
//

import UIKit

extension UIViewController {
    func present(_ viewController: UIViewController) async {
        await withCheckedContinuation { continuation in
            present(viewController, animated: true) {
                continuation.resume()
            }
        }
    }
}
