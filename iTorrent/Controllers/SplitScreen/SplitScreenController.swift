//
//  SplitScreenController.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 03.05.2022.
//

import MVVMFoundation

class SplitScreenController: MvvmSplitViewController<SplitScreenViewModel> {
    override func createEmptyViewController() -> UIViewController {
        return EmptyViewController()
    }

//    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
//        super.viewWillTransition(to: size, with: coordinator)
//
//        guard !isCollapsed, viewControllers.count > 1 else { return }
//
//        let margin: CGFloat = viewControllers[1].view!.frame.width > 750 ? 52 : 0
//        viewControllers[1].view?.layoutMargins.left = margin
//        viewControllers[1].view?.layoutMargins.right = margin
//    }
}
