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
        window?.tintColor = .accent
    }

    override func register(in container: Container) {
        container.register(type: UINavigationController.self, factory: BaseNavigationController.init)
        container.register(type: UISplitViewController.self, factory: BaseSplitViewController.init)
        container.registerSingleton(factory: { TorrentService.shared })
        container.registerSingleton(factory: NetworkMonitoringService.init)
        container.registerSingleton(factory: { PreferencesStorage.shared })
    }

    override func routing(in router: Router) {
        //MARK: Controllers
        router.register(TorrentListViewController<TorrentListViewModel>.self)
        router.register(TorrentDetailsViewController<TorrentDetailsViewModel>.self)
        router.register(TorrentFilesViewController<TorrentFilesViewModel>.self)
        router.register(TorrentAddViewController<TorrentAddViewModel>.self)
        router.register(TorrentTrackersViewController<TorrentTrackersViewModel>.self)

        router.register(BasePreferencesViewController<PreferencesViewModel>.self)
        router.register(BasePreferencesViewController<ProxyPreferencesViewModel>.self)
        router.register(BasePreferencesViewController<ConnectionPreferencesViewModel>.self)

        //MARK: Cells
        router.register(TorrentListItemView.self)
        router.register(TorrentDetailProgressCellView.self)

        router.register(TrackerCellView.self)

        router.register(DetailCellView.self)
        router.register(ToggleCellView.self)

        router.register(PRSwitchView.self)
        router.register(PRButtonView.self)
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
