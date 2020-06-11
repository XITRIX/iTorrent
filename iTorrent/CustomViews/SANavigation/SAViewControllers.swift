//
//  SAViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 01.04.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

protocol NavigationProtocol {
    var toolBarIsHidden: Bool? { get }
}

class SAViewController: UIViewController, NavigationProtocol {
    var toolBarIsHidden: Bool? {
        nil
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let nav = navigationController as? SANavigationController,
            nav.viewControllers.last == self {
            nav.locker = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let toolBarIsHidden = toolBarIsHidden {
            navigationController?.setToolbarHidden(toolBarIsHidden, animated: false)
        }
    }
}

class SATableViewController: UITableViewController, NavigationProtocol {
    var toolBarIsHidden: Bool? {
        nil
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let nav = navigationController as? SANavigationController,
            nav.viewControllers.last == self {
            nav.locker = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let toolBarIsHidden = toolBarIsHidden {
            navigationController?.setToolbarHidden(toolBarIsHidden, animated: false)
        }
    }
}
