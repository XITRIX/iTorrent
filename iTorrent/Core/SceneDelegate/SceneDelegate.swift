//
//  SceneDelegate.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 29/10/2023.
//

import LibTorrent
import MvvmFoundation
import UIKit
import AVKit

class SceneDelegate: MvvmSceneDelegate {
    override func initialSetup() {
        UIView.enableUIColorsToLayer()
    }

    override func register(in container: Container) {
        registerAVPlayer(in: container)
        container.register(type: UINavigationController.self, factory: BaseNavigationController.init)
        container.register(type: UISplitViewController.self, factory: BaseSplitViewController.init)
        container.registerSingleton(factory: { TorrentService.shared })
        container.registerSingleton(factory: { PreferencesStorage.shared })
        container.registerSingleton(factory: { BackgroundService.shared })
        container.registerSingleton(factory: NetworkMonitoringService.init)
        container.registerSingleton(factory: ImageLoader.init)
        container.registerDaemon(factory: PatreonService.init)
        container.registerDaemon(factory: TorrentMonitoringService.init)
        container.registerDaemon(factory: RssFeedProvider.init)
        container.registerDaemon(factory: WebServerService.init)
        container.registerDaemon(factory: LiveActivityService.init)
        container.registerDaemon(factory: IntentsService.init)
        container.registerDaemon(factory: AdsManager.init)
    }

    override func routing(in router: Router) {
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

        // MARK: Controllers
        router.register(BaseHostingViewController<StoragePreferencesView>.self)

        router.register(TorrentListViewController<TorrentListViewModel>.self)
        router.register(TorrentDetailsViewController<TorrentDetailsViewModel>.self)
        router.register(TorrentFilesViewController<TorrentFilesViewModel>.self)
        router.register(TorrentAddViewController<TorrentAddViewModel>.self)
        router.register(TorrentTrackersViewController<TorrentTrackersViewModel>.self)

        router.register(BasePreferencesViewController<PreferencesViewModel>.self)
        router.register(BasePreferencesViewController<ProxyPreferencesViewModel>.self)
        router.register(BasePreferencesViewController<ConnectionPreferencesViewModel>.self)
        router.register(BasePreferencesViewController<FileSharingPreferencesViewModel>.self)
        router.register(PreferencesSectionGroupingViewController.self)
        router.register(PatreonPreferencesViewController.self)

        router.register(RssListViewController.self)
        router.register(RssChannelViewController.self)
        router.register(RssDetailsViewController.self)
        router.register(RssListPreferencesViewController.self)
        router.register(RssSearchViewController.self)
    }

    override func resolveRootVC(with router: Router) -> UIViewController {
        let vc = router.resolve(TorrentListViewModel())

        let nvc = UINavigationController.resolve()
        nvc.viewControllers = [vc]

        let svc = UISplitViewController.resolve()
        svc.viewControllers = [nvc]

        return svc
    }

    override func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        super.scene(scene, willConnectTo: session, options: connectionOptions)
        connectionOptions.urlContexts.forEach { context in
            let url = context.url
            processURL(url)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        URLContexts.forEach { context in
            let url = context.url
            processURL(url)
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        startBackgroundIfNeeded()
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        stopBackground()
    }

    override func binding() {
        disposeBag.bind {
            tintColorBind
            appAppearanceBind
            backgroundDownloadModeBind
            backgroundStateObserverBind
        }
    }
}
