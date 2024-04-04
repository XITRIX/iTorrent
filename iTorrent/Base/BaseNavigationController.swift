//
//  BaseNavigationController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 30/10/2023.
//

import UIKit

class BaseNavigationController: SANavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.prefersLargeTitles = true
    }
}
