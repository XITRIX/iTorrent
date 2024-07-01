//
//  SAViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 01.04.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import MvvmFoundation
import Combine
import UIKit

class SAViewController<ViewModel: MvvmViewModelProtocol>: MvvmViewController<ViewModel> {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let nav = navigationController as? SANavigationController,
           nav.viewControllers.last == self
        {
            nav.locker = false
        }
    }
}

class SAHostingViewController<View: MvvmSwiftUIViewProtocol>: MvvmHostingViewController<View> {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let nav = navigationController as? SANavigationController,
           nav.viewControllers.last == self
        {
            nav.locker = false
        }
    }
}
