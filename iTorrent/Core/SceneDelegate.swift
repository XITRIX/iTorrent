//
//  SceneDelegate.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 29/10/2023.
//

import MvvmFoundation
import UIKit

class SceneDelegate: MvvmSceneDelegate {
    override func register(in container: Container) {
        container.register(type: UINavigationController.self, factory: BaseNavigationController.init)
        container.registerSingleton(factory: TorrentService.init)
    }

    override func routing(in router: Router) {
        router.register(TorrentListViewController<TorrentListViewModel>.self)
        router.register(TorrentDetailsViewController<TorrentDetailsViewModel>.self)

        router.register(TorrentListItemView.self)
        router.register(DetailCellView.self)
    }

    override func resolveRootVC(with router: Router) -> UIViewController {
        let vc = router.resolve(TorrentListViewModel())
        let nvc = UINavigationController.resolve()
        nvc.viewControllers = [vc]
        return nvc
    }
}
