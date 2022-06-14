//
//  BaseViewController.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 04.05.2022.
//

import Foundation
import MVVMFoundation

class BaseViewController<ViewModel: MvvmViewModel>: SAViewController<ViewModel> {
    var adoptMarginsToContentWidth: Bool { true }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateMargins(view.frame.size)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Large title dirty fix
//        navigationController?.view.setNeedsLayout()
//        navigationController?.view.layoutIfNeeded()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { [self] _ in
            updateMargins(size)
        }
    }

    func updateMargins(_ size: CGSize) {
        guard adoptMarginsToContentWidth else { return }
        
        let margin: CGFloat = size.width < 750 ? 0 : 54
        view.layoutMargins.left = margin
        view.layoutMargins.right = margin
    }
}
