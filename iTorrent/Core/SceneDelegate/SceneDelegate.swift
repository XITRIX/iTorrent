//
//  SceneDelegate.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 29/10/2023.
//

import LibTorrent
import MvvmFoundation
import UIKit

class SceneDelegate: MvvmSceneDelegate {
    override func initialSetup() {
        UIView.enableUIColorsToLayer()
    }

    override func register(in container: Container) {
        container.register(type: UINavigationController.self, factory: BaseNavigationController.init)
        container.register(type: UISplitViewController.self, factory: BaseSplitViewController.init)
        container.registerSingleton(factory: { TorrentService.shared })
        container.registerSingleton(factory: NetworkMonitoringService.init)
        container.registerSingleton(factory: { PreferencesStorage.shared })
        container.registerSingleton(factory: { BackgroundService.shared })
        container.registerDaemon(factory: TorrentMonitoringService.init)
        container.registerDaemon(factory: RssFeedProvider.init)
    }

    override func routing(in router: Router) {
        // MARK: Controllers
        router.register(TorrentListViewController<TorrentListViewModel>.self)
        router.register(TorrentDetailsViewController<TorrentDetailsViewModel>.self)
        router.register(TorrentFilesViewController<TorrentFilesViewModel>.self)
        router.register(TorrentAddViewController<TorrentAddViewModel>.self)
        router.register(TorrentTrackersViewController<TorrentTrackersViewModel>.self)

        router.register(BasePreferencesViewController<PreferencesViewModel>.self)
        router.register(BasePreferencesViewController<ProxyPreferencesViewModel>.self)
        router.register(BasePreferencesViewController<ConnectionPreferencesViewModel>.self)
        router.register(PreferencesSectionGroupingViewController.self)

        router.register(RssListViewController.self)
        router.register(RssChannelViewController.self)
        router.register(RssDetailsViewController.self)
        router.register(RssListPreferencesViewController.self)

        // MARK: Cells
        router.register(TorrentListItemView.self)
        router.register(TorrentDetailProgressCellView.self)

        router.register(RssFeedCell.self)
        router.register(RssChannelItemCell.self)

        router.register(TrackerCellView.self)

        router.register(DetailCellView.self)
        router.register(ToggleCellView.self)

        router.register(PRSwitchView.self)
        router.register(PRButtonView.self)
        router.register(PRStorageCell.self)
        router.register(PRColorPickerCell.self)
    }

    override func resolveRootVC(with router: Router) -> UIViewController {
        let vc = router.resolve(TorrentListViewModel())

        let nvc = UINavigationController.resolve()
        nvc.viewControllers = [vc]

        let svc = UISplitViewController.resolve()
        svc.viewControllers = [nvc]

        return svc
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        URLContexts.forEach { context in
            let url = context.url
            processURL(url)
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        startBackgroundIfNeeded()
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        stopBackground()
    }

    override func binding() {
        bindLiveActivity()
        disposeBag.bind {
            tintColorBind
            appAppearanceBind
            backgroundDownloadModeBind
            backgroundStateObserverBind
        }
    }
}
