//
//  BaseViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 29/10/2023.
//

import MvvmFoundation

class BaseViewController<ViewModel: MvvmViewModelProtocol>: MvvmViewController<ViewModel> {
    var isToolbarItemsHidden: Bool { toolbarItems?.isEmpty ?? true }

    override func viewDidLoad() {
        super.viewDidLoad()
        #if os(visionOS)
        view.backgroundColor = nil
        #endif
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(isToolbarItemsHidden, animated: false)
    }
}
