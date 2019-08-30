//
//  UpdatesDialog.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 21/08/2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class UpdatesDialog {
	static func summon(forced: Bool = false) -> ThemedUIAlertController? {
		let localurl = Bundle.main.url(forResource: "Version", withExtension: "ver")
		if let localVersion = try? String(contentsOf: localurl!) {
            if (!UserPreferences.versionNews.value || forced) {
				let title = localVersion + NSLocalizedString("info", comment: "")
				let newsController = ThemedUIAlertController(title: title.replacingOccurrences(of: "\n", with: ""), message: NSLocalizedString("UpdateText", comment: ""), preferredStyle: .alert)
				let close = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .cancel) { _ in
					UserPreferences.versionNews.value = true
				}
				newsController.addAction(close)
				return newsController
			}
		}
		return nil
	}
}
