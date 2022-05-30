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
        super.registerContainer()

        // Register Services
        container.registerSingleton { TorrentManager() }
        container.registerSingleton { PropertyStorage() }
        container.registerSingleton { TorrentAddingService() }
        container.registerSingleton { TorrentBackgroundTask() }

        // Register ViewControllers
        container.register { SplitScreenController() }
        container.register { TorrentsListViewController() }
        container.register { TorrentDetailsController() }
        container.register { TorrentFilesController() }
        container.register { TorrentAddingController() }
        container.register { TorrentTrackersListController() }
        container.register { TorrentSettingsController() }

        // Register ViewModels
        container.register { SplitScreenViewModel() }
        container.register { TorrentsListViewModel() }
        container.register { TorrentDetailsViewModel() }
        container.register { TorrentFilesViewModel() }
        container.register { TorrentAddingViewModel() }
        container.register { TorrentTrackersListViewModel() }
        container.register { TorrentSettingsViewModel() }

        // Add custom Navigation Controller
        container.register(type: UINavigationController.self) { BaseNavigationController() }
    }

    override func registerRouting() {
        // Register Root
        router.registerRoot(SplitScreenViewModel.self, wrappedInNavigation: false)

        // Register Routing
        router.register(viewModel: SplitScreenViewModel.self, viewController: SplitScreenController.self)
        router.register(viewModel: TorrentsListViewModel.self, viewController: TorrentsListViewController.self)
        router.register(viewModel: TorrentDetailsViewModel.self, viewController: TorrentDetailsController.self)
        router.register(viewModel: TorrentFilesViewModel.self, viewController: TorrentFilesController.self)
        router.register(viewModel: TorrentAddingViewModel.self, viewController: TorrentAddingController.self)
        router.register(viewModel: TorrentTrackersListViewModel.self, viewController: TorrentTrackersListController.self)
        router.register(viewModel: TorrentSettingsViewModel.self, viewController: TorrentSettingsController.self)
    }
}
