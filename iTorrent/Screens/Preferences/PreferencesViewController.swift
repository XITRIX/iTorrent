//
//  PreferencesViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 06/11/2023.
//

import MvvmFoundation
import UIKit

class PreferencesViewController<VM: PreferencesViewModel>: BaseViewController<VM> {
    @IBOutlet private var collectionView: MvvmCollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = String(localized: "preferences")
        navigationItem.largeTitleDisplayMode = .never

        disposeBag.bind {
            viewModel.sections.sink { [unowned self] sections in
                collectionView.sections.send(sections)
            }

            viewModel.dismissSelection.sink { [unowned self] _ in
                collectionView.diffDataSource.deselectItems()
            }
        }

#if os(visionOS)
        view.backgroundColor = .secondarySystemBackground
#endif
    }
}
