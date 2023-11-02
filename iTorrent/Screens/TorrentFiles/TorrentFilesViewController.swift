//
//  TorrentFilesViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 01/11/2023.
//

import UIKit
import MvvmFoundation

class TorrentFilesViewController<VM: TorrentFilesViewModel>: BaseViewController<VM> {
    @IBOutlet private var collectionView: MvvmCollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Files"
        disposeBag.bind {
            viewModel.$sections.sink { [unowned self] sections in
                if collectionView.diffDataSource.snapshot().sectionIdentifiers.differs(from: sections) {
                    collectionView.diffDataSource.applyModels(sections)
                }
            }
        }
    }

}
