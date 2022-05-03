//
//  BaseNavigationController.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 04.05.2022.
//

import UIKit
import MVVMFoundation

class BaseNavigationController: SANavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemBackground
    }
}
