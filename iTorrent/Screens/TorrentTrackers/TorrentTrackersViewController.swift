//
//  TorrentTrackersViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 10/11/2023.
//

import MvvmFoundation
import UIKit

class TorrentTrackersViewController<VM: TorrentTrackersViewModel>: BaseViewController<VM> {
    @IBOutlet private var collectionView: MvvmCollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Trackers"

        disposeBag.bind {
            viewModel.$sections.sink { [unowned self] sections in
                collectionView.diffDataSource.applyModels(sections)
            }
        }
    }
}
