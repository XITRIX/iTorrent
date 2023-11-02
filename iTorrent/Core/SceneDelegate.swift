//
//  SceneDelegate.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 29/10/2023.
//

import MvvmFoundation
import UIKit

class SceneDelegate: MvvmSceneDelegate {
    override func initialSetup() {
        window?.tintColor = .systemRed
    }

    override func register(in container: Container) {
        container.register(type: UINavigationController.self, factory: BaseNavigationController.init)
        container.register(type: UISplitViewController.self, factory: BaseSplitViewController.init)
        container.registerSingleton(factory: TorrentService.init)
    }

    override func routing(in router: Router) {
        router.register(TorrentListViewController<TorrentListViewModel>.self)
        router.register(TorrentDetailsViewController<TorrentDetailsViewModel>.self)
        router.register(TorrentFilesViewController<TorrentFilesViewModel>.self)

        router.register(TorrentListItemView.self)
        router.register(TorrentDetailProgressCellView.self)
        router.register(TorrentFilesItemView.self)

        router.register(DetailCellView.self)
        router.register(ToggleCellView.self)
    }

    override func resolveRootVC(with router: Router) -> UIViewController {
        let vc = router.resolve(TorrentListViewModel())

        let nvc = UINavigationController.resolve()
        nvc.viewControllers = [vc]

        let svc = UISplitViewController.resolve()
        svc.viewControllers = [nvc]
//        svc.setViewController(nvc, for: .primary)

        return svc
    }
}
