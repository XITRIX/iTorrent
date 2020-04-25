//
//  SAViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 01.04.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

class SAViewController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let nav = navigationController as? SANavigationController,
            nav.viewControllers.last == self {
            nav.locker = false
        }
    }
}

class SATableViewController: UITableViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let nav = navigationController as? SANavigationController,
            nav.viewControllers.last == self {
            nav.locker = false
        }
    }
}
