//
//  BaseViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 29/10/2023.
//

import MvvmFoundation

class BaseViewController<ViewModel: MvvmViewModelProtocol>: MvvmViewController<ViewModel> {
    override func viewDidLoad() {
        super.viewDidLoad()
//        title = viewModel.title.value
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(toolbarItems?.isEmpty ?? true, animated: animated)
    }
}
