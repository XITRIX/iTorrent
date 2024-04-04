//
//  BasePreferencesViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 02/04/2024.
//

import MvvmFoundation
import UIKit

class BasePreferencesViewController<VM: BasePreferencesViewModel>: BaseViewController<VM> {
    @IBOutlet private(set) var collectionView: MvvmCollectionView!

    override var nibName: String? {
        "\(BasePreferencesViewController.self)".replacingOccurrences(of: "<\(VM.self)>", with: "")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never

        disposeBag.bind {
            viewModel.title.sink { [unowned self] title in
                self.title = title
            }

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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        smoothlyDeselectRows(in: collectionView)
    }
}
