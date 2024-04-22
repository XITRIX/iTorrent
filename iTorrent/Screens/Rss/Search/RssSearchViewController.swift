//
//  RssSearchViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 22/04/2024.
//

import UIKit

class RssSearchViewController<VM: RssSearchViewModel>: BaseCollectionViewController<VM> {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
    }
}
