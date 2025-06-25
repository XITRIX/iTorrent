//
//  RssChannelViewController.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 08.04.2024.
//

import MvvmFoundation
import UIKit

class RssChannelViewController<VM: RssChannelViewModel>: BaseCollectionViewController<VM> {
    private let actionsButton: UIBarButtonItem

    required init(viewModel: VM) {
        if #available(iOS 26, *) {
            actionsButton = UIBarButtonItem(title: "Actions", image: .init(systemName: "ellipsis"))
        } else {
            actionsButton = UIBarButtonItem(title: "Actions", image: .init(systemName: "ellipsis.circle"))
        }
        
        super.init(viewModel: viewModel)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    private let searchController: UISearchController = {
        let searchController = UISearchController()
        searchController.searchBar.placeholder = %"common.search"
        return searchController
    }()
}

private extension RssChannelViewController {
    func setup() {
        binding()
        
        view.backgroundColor = .systemBackground

        actionsButton.menu = .init(children: [
            UIAction(title: %"rsschannel.readAll", image: .init(systemName: "checkmark.circle")) { [unowned self] _ in
                viewModel.readAll()
            },
            viewModel.model.link.map { url in
                UIAction(title: %"rsschannel.safari", image: .init(systemName: "safari")) { [unowned self] _ in
                    let safari = BaseSafariViewController(url: url)
                    present(safari, animated: true)
                }
            }
        ].compactMap { $0 })

        navigationItem.searchController = searchController
        navigationItem.trailingItemGroups = [.fixedGroup(items: [actionsButton])]

        collectionView.contextMenuConfigurationForItemsAt = { [unowned self] indexPaths, _ in
            guard let indexPath = indexPaths.first,
                  let rssItemModel = viewModel.items[indexPath.item].model
            else { return nil }

            return UIContextMenuConfiguration {
                RssDetailsViewModel.resolveVC(with: rssItemModel)
            }
        }

        collectionView.willPerformPreviewActionForMenuWith = { [unowned self] _, animator in
            animator.addCompletion { [self] in
                guard let preview = animator.previewViewController
                else { return }

                if let mvvmcv = preview as? (any MvvmViewControllerProtocol),
                   let vm = mvvmcv.viewModel as? RssDetailsViewModel,
                   let rssItemModel = vm.rssModel
                {
                    viewModel.setSeen(true, for: rssItemModel)
                }

                viewModel.navigationService?()?.navigate(to: preview, by: .detail(asRoot: true))
                if let nav = preview.navigationController as? SANavigationController,
                   nav.viewControllers.last == preview
                {
                    nav.locker = false
                }
            }
        }
    }

    func binding() {
        disposeBag.bind {
            viewModel.$title.sink { [unowned self] text in
                title = text
            }
        }

        searchController.searchBar.textDidChangePublisher.assign(to: &viewModel.$searchQuery)
        searchController.searchBar.cancelButtonClickedPublisher.map { "" }.assign(to: &viewModel.$searchQuery)
    }
}
