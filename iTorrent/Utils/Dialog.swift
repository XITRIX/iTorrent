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
    static func withTimer(_ presenter: UIViewController,title: String?, message: String?) {
        let alert = ThemedUIAlertController(title:title, message: message, preferredStyle: .alert)
        presenter.present(alert, animated: true, completion: nil)
        // change alert timer to 2 seconds, then dismiss
        let when = DispatchTime.now() + 2
        DispatchQueue.main.asyncAfter(deadline: when) {
            alert.dismiss(animated: true, completion: nil)
        }
    }
    
    static func show(_ presenter: UIViewController?, title: String?, message: String?) {
        let dialog = ThemedUIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: Localize.get("Close"), style: .cancel)
        dialog.addAction(ok)
        presenter?.present(dialog, animated: true)
    }
    
    static func createUpdateLogs(forced: Bool = false, finishAction: (() -> ())? = nil) -> ThemedUIAlertController? {
        let localUrl = Bundle.main.url(forResource: "Version", withExtension: "ver")
        if let localVersion = try? String(contentsOf: localUrl!) {
            if !UserPreferences.versionNews || forced {
                let title = localVersion + NSLocalizedString("info", comment: "")
                let newsController = ThemedUIAlertController(title: title.replacingOccurrences(of: "\n", with: ""), message: NSLocalizedString("UpdateText", comment: ""), preferredStyle: .alert)
                let close = UIAlertAction(title: Localize.get("Close"), style: .cancel) { _ in
                    UserPreferences.versionNews = true
                    finishAction?()
                }
                newsController.addAction(close)
                return newsController
            }
        }
        finishAction?()
        return nil
    }

    static func createNewsAlert() -> ThemedUIAlertController? {
        if #available(iOS 13, *) {
            let code = "1"
            if !UserPreferences.alertDialog(code: code).value {
                let newsController = ThemedUIAlertController(title: Localize.get("Dialogs.News.Title"), message: Localize.get("Dialogs.News.Message"), preferredStyle: .alert)
                let close = UIAlertAction(title: Localize.get("Close"), style: .cancel) { _ in
                    UserPreferences.alertDialog(code: code).value = true
                }
                newsController.addAction(close)
                return newsController
            }
        }
        return nil
    }
}
