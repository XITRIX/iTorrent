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
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        presenter?.present(alert, animated: true, completion: nil)
        // change alert timer to 2 seconds, then dismiss
        let when = DispatchTime.now() + 2
        DispatchQueue.main.asyncAfter(deadline: when) {
            alert.dismiss(animated: true, completion: nil)
        }
    }

    static func withTextField(_ presenter: UIViewController?, title: String? = nil, message: String? = nil, textFieldConfiguration: ((UITextField) -> ())?, cancelText: String = "Close", okText: String = "OK", okAction: @escaping (UITextField) -> ()) {
        let dialog = UIAlertController(title: title, message: message, preferredStyle: .alert)
        dialog.addTextField { textField in
            textFieldConfiguration?(textField)
        }

        let cancel = UIAlertAction(title: cancelText, style: .cancel)
        let ok = UIAlertAction(title: okText, style: .default) { _ in
            okAction(dialog.textFields![0])
        }

        dialog.addAction(cancel)
        dialog.addAction(ok)

        presenter?.present(dialog, animated: true)
    }

    static func withButton(_ presenter: UIViewController?, title: String? = nil, message: String? = nil, okTitle: String, action: @escaping ()->()) {
        let dialog = UIAlertController(title: title,
                                             message: message,
                                             preferredStyle: .alert)

        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        let ok = UIAlertAction(title: okTitle, style: .default) { _ in
            action()
        }

        dialog.addAction(cancel)
        dialog.addAction(ok)

        presenter?.present(dialog, animated: true)
    }

    static func show(_ presenter: UIViewController?, title: String?, message: String?, closeText: String = "Close") {
        let dialog = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: closeText, style: .cancel)
        dialog.addAction(ok)
        presenter?.present(dialog, animated: true)
    }

//    static func createUpdateLogs(forced: Bool = false, closeAction: (() -> ())? = nil) -> UIAlertController? {
//        let localUrl = Bundle.main.url(forResource: "Version", withExtension: "ver")
//        if let localVersion = try? String(contentsOf: localUrl!) {
//            if !UserPreferences.versionNews || forced {
//                let title = localVersion + NSLocalizedString("info", comment: "")
//                let newsController = UIAlertController(title: title.replacingOccurrences(of: "\n", with: ""), message: "UpdateText".localized, preferredStyle: .alert)
//                let close = UIAlertAction(title: "Close", style: .cancel) { _ in
//                    UserPreferences.versionNews = true
//                    closeAction?()
//                }
//                newsController.addAction(close)
//                return newsController
//            }
//        }
//        closeAction?()
//        return nil
//    }
}
