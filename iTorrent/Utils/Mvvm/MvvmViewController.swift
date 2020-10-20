//
//  MvvmViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 03.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

class MvvmViewController<T: ViewModel>: ThemedUIViewController {
    var viewModel: T!

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = initializeViewModel()
        viewModel.viewDidLoad()
        setupViews()
        binding()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.viewWillAppear()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.viewDidAppear()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.viewWillDisappear()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.viewDidDisappear()
    }

    func initializeViewModel() -> T {
        T()
    }
    
    func setupViews() {}

    func binding() {}
}
