//
//  RssChannelViewController.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 08.04.2024.
//

import MvvmFoundation
import UIKit

class RssChannelViewController<VM: RssChannelViewModel>: BaseCollectionViewController<VM> {
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
}

private extension RssChannelViewController {
    func setup() {
        binding()
    }

    func binding() {
        disposeBag.bind {
            viewModel.$title.sink { [unowned self] text in
                title = text
            }
        }
    }
}
