//
//  CoreMvvm.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 28.03.2022.
//

import UIKit
import MVVMFoundation
import TorrentKit

class CoreMvvm: MVVM {
    override func registerContainer() {
        // Register Services
        container.registerSingleton { TorrentManager() }
        container.registerSingleton { PropertyStorage() }
//
//        // Register ViewControllers
        container.register { TorrentsListViewController() }
        container.register { TorrentDetailsController() }
        container.register { TorrentFilesController() }
        container.register { TorrentAddingController() }
        container.register { TorrentTrackersListController() }
//
//        // Register ViewModels
        container.register { TorrentsListViewModel() }
        container.register { TorrentDetailsViewModel() }
        container.register { TorrentFilesViewModel() }
        container.register { TorrentAddingViewModel() }
        container.register { TorrentTrackersListViewModel() }

        // Add custom Navigation Controller
        container.register { () -> UINavigationController in
            let nvc = UINavigationController()
            nvc.navigationBar.prefersLargeTitles = true
            return nvc
        }
    }

    override func registerRouting() {
        // Register Root
        router.registerRoot(TorrentsListViewModel.self, wrappedInNavigation: true)
//
//        // Register Routing
        router.register(viewModel: TorrentsListViewModel.self, viewController: TorrentsListViewController.self)
        router.register(viewModel: TorrentDetailsViewModel.self, viewController: TorrentDetailsController.self)
        router.register(viewModel: TorrentFilesViewModel.self, viewController: TorrentFilesController.self)
        router.register(viewModel: TorrentAddingViewModel.self, viewController: TorrentAddingController.self)
        router.register(viewModel: TorrentTrackersListViewModel.self, viewController: TorrentTrackersListController.self)
    }
}
