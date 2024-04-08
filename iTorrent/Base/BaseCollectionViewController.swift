//
//  BaseCollectionViewController.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 08.04.2024.
//

import UIKit
import MvvmFoundation

class BaseCollectionViewController<VM: BaseCollectionViewModel>: BaseViewController<VM> {
    var collectionView: MvvmCollectionView! { view as? MvvmCollectionView }

    override func loadView() {
        view = MvvmCollectionView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

#if os(visionOS)
        view.backgroundColor = .secondarySystemBackground
#else
        view.backgroundColor = .systemGroupedBackground
#endif

        disposeBag.bind {
            viewModel.$sections.sink { [unowned self] sections in
                collectionView.diffDataSource.applyModels(sections)
            }

            collectionView.$selectedIndexPaths.sink { [unowned self] indexPaths in
                viewModel.selectedIndexPaths = indexPaths
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        smoothlyDeselectRows(in: collectionView)
    }
}
