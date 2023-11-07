//
//  PreferencesViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 06/11/2023.
//

import UIKit

class PreferencesViewController<VM: PreferencesViewModel>: BaseViewController<VM> {

    override func viewDidLoad() {
        super.viewDidLoad()

        title = String(localized: "preferences")
    }

}
