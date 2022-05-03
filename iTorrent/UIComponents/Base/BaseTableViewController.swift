//
//  BaseTableViewController.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 04.05.2022.
//

import Foundation
import MVVMFoundation

class BaseTableViewController<ViewModel: MvvmViewModel>: SATableViewController<ViewModel> {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Large title dirty fix
//        navigationController?.view.setNeedsLayout()
//        navigationController?.view.layoutIfNeeded()
    }
}
