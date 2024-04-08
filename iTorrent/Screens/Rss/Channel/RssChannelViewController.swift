//
//  RssChannelViewController.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 08.04.2024.
//

import MvvmFoundation
import SafariServices
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

        if let url = viewModel.model.link {
            navigationItem.trailingItemGroups = [.fixedGroup(items: [.init(image: .init(systemName: "safari"), primaryAction: .init(handler: { [unowned self] _ in
                present(SFSafariViewController(url: url), animated: true)
            }))])]
        }
    }

    func binding() {
        disposeBag.bind {
            viewModel.$title.sink { [unowned self] text in
                title = text
            }
        }
    }
}
