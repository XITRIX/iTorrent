//
//  SplitViewController.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 15.12.2022.
//  Copyright © 2022  XITRIX. All rights reserved.
//

import UIKit

class SplitViewController: ThemedUISplitViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !isCollapsed,
           viewControllers.count < 2
        {
            showDetailViewController(Utils.createEmptyViewController(), sender: self)
        }
    }
}
