//
//  TorrentListViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 29/10/2023.
//

import Combine
import CombineCocoa
import LibTorrent
import MvvmFoundation
import SwiftUI
import UIKit

class TLSearchController: UISearchController {
    let isActivePublisher = PassthroughRelay<Bool>()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isActivePublisher.send(true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isActivePublisher.send(false)
        transitionCoordinator?.animate(alongsideTransition: { _ in }, completion: { [self] ctx in
            if ctx.isCancelled {
                isActivePublisher.send(true)
            }
        })
    }
}

class TorrentListViewController<VM: TorrentListViewModel>: BaseViewController<VM> {
    @IBOutlet private var collectionView: MvvmCollectionView!
    @IBOutlet private var adView: AdView!

    private let addButton = UIBarButtonItem(title: %"common.add", image: .init(systemName: "plus"))
    private let preferencesButton = UIBarButtonItem(title: %"preferences", image: .init(systemName: "gearshape.fill"))
    private let sortButton = UIBarButtonItem(title: %"list.sort", image: .icSort)
    private let rssButton = UIBarButtonItem()

    private let shareButton = UIBarButtonItem(title: %"common.share", image: .init(systemName: "square.and.arrow.up"))
    private let playButton = UIBarButtonItem()
    private let pauseButton = UIBarButtonItem()
    private let rehashButton = UIBarButtonItem()
    private let deleteButton = UIBarButtonItem()

    private lazy var delegates = Delegates(parent: self)
    private lazy var searchVC: TLSearchController = {
        let rssSeacrchViewController = viewModel.rssSearchViewModel.resolveVC()
        let searchController = TLSearchController(searchResultsController: rssSeacrchViewController)
        return searchController
    }()

    private lazy var documentPicker = makeDocumentPicker()
    private let tagsView = makeTagsView()

    private var getToolBarItems: [UIBarButtonItem] {
        collectionView.isEditing ?
            [
                playButton,
                fixedSpacing,
                pauseButton,
                fixedSpacing,
                rehashButton,
                .flexibleSpace(),
                deleteButton
            ].compactMap { $0 } :
            [addButton, .init(systemItem: .flexibleSpace), preferencesButton]
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()

        searchVC.searchBar.textDidChangePublisher.assign(to: &viewModel.$searchQuery)

        searchVC.searchBar.cancelButtonClickedPublisher
            .map { "" }.assign(to: &viewModel.$searchQuery)

        addButton.menu = UIMenu(title: %"list.add.title", children: [
            UIAction(title: %"list.add.files", image: .init(systemName: "doc.fill.badge.plus")) { [unowned self] _ in
                present(documentPicker, animated: true)
            },
            UIAction(title: %"list.add.magnet", image: .init(resource: .icMagnet)) { [unowned self] _ in
                present(makeMagnetAlert(), animated: true)
            },
            UIAction(title: %"list.add.url", image: .init(systemName: "link.badge.plus")) { [unowned self] _ in
                present(makeUrlAlert(), animated: true)
            }
        ])

        playButton.primaryAction = .init(title: %"details.start", image: .init(systemName: "play.fill"), handler: { [unowned self] _ in
            viewModel.resumeAllSelected(at: collectionView.indexPathsForSelectedItems ?? [])
        })

        pauseButton.primaryAction = .init(title: %"details.pause", image: .init(systemName: "pause.fill"), handler: { [unowned self] _ in
            viewModel.pauseAllSelected(at: collectionView.indexPathsForSelectedItems ?? [])
        })

        rehashButton.primaryAction = .init(title: %"details.rehash", image: .init(systemName: "arrow.clockwise"), handler: { [unowned self] _ in
            viewModel.rehashAllSelected(at: collectionView.indexPathsForSelectedItems ?? [])
        })

        deleteButton.primaryAction = .init(title: %"common.delete", image: .init(systemName: "trash"), handler: { [unowned self] _ in
            viewModel.deleteAllSelected(at: collectionView.indexPathsForSelectedItems ?? [])
        })

        Task {
            // Delay to show SearchBar on screen appear
            disposeBag.bind {
                viewModel.$sections.uiSink { [unowned self] sections in
                    collectionView.sections.send(sections)
                }
            }
        }

        binding()

        navigationItem.leadingItemGroups.append(.fixedGroup(items: [editButtonItem]))
        navigationItem.trailingItemGroups.append(.fixedGroup(items: [rssButton, sortButton]))
        toolbarItems = getToolBarItems

        collectionView.contextMenuConfigurationForItemsAt = { [unowned self] indexPaths, _ in
            guard indexPaths.count > 0 else { return nil }

            if indexPaths.count == 1 {
                guard let indexPath = indexPaths.first,
                      let torrentHandle = (viewModel.sections[indexPath.section].items[indexPath.item] as? TorrentListItemViewModel)?.torrentHandle
                else { return nil }

                return UIContextMenuConfiguration {
                    TorrentDetailsViewModel.resolveVC(with: torrentHandle)
                } actionProvider: { _ in
                    let start = UIAction(title: %"details.start", image: .init(systemName: "play.fill"), attributes: torrentHandle.snapshot.canResume ? [] : .hidden, handler: { _ in
                        torrentHandle.resume()
                    })
                    let pause = UIAction(title: %"details.pause", image: .init(systemName: "pause.fill"), attributes: torrentHandle.snapshot.canPause ? [] : .hidden, handler: { _ in
                        torrentHandle.pause()
                    })
                    let delete = UIAction(title: %"common.delete", image: UIImage(systemName: "trash.fill"), attributes: .destructive) { [unowned self] _ in
                        viewModel.removeTorrent(torrentHandle)
                    }

                    return UIMenu(title: torrentHandle.snapshot.name, children: [
                        start,
                        pause,
                        UIMenu(options: .displayInline,
                               children: [delete])
                    ])
                }
            } else {
                let handles = indexPaths.compactMap { indexPath in (viewModel.sections[indexPath.section].items[indexPath.item] as? TorrentListItemViewModel)?.torrentHandle }
                return UIContextMenuConfiguration {
                    nil
                } actionProvider: { _ in
                    let start = UIAction(title: %"details.start", image: .init(systemName: "play.fill"), handler: { _ in
                        handles.forEach { $0.resume() }
                    })
                    let pause = UIAction(title: %"details.pause", image: .init(systemName: "pause.fill"), handler: { _ in
                        handles.forEach { $0.pause() }
                    })
//                    let delete = UIAction(title: %"common.delete", image: UIImage(systemName: "trash.fill"), attributes: .destructive) { [unowned self] _ in
//                        viewModel.removeTorrent(torrentHandle)
//                    }

                    return UIMenu(children: [
                        start,
                        pause
//                        UIMenu(options: .displayInline,
//                               children: [delete])
                    ])
                }
            }
        }

        collectionView.willPerformPreviewActionForMenuWith = { [unowned self] _, animator in
            animator.addCompletion { [self] in
                if let preview = animator.previewViewController {
                    viewModel.navigationService?()?.navigate(to: preview, by: .detail(asRoot: true))
                    if let nav = preview.navigationController as? SANavigationController,
                       nav.viewControllers.last == preview
                    {
                        nav.locker = false
                    }
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        smoothlyDeselectRows(in: collectionView)
    }

    override func viewLayoutMarginsDidChange() {
        super.viewLayoutMarginsDidChange()

        tagsView.contentInset.left = view.layoutMargins.left - tagsView.safeAreaInsets.left
        tagsView.contentInset.right = view.layoutMargins.right - tagsView.safeAreaInsets.right
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        collectionView.isEditing = editing
        toolbarItems = getToolBarItems
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        additionalSafeAreaInsets.bottom = adView.frame.height
        tagsView.scrollToSelectedItem()

        if #available(iOS 26, *),
           let splitViewController
        {
            if !splitViewController.isCollapsed {
                view.backgroundColor = .clear
            } else {
                view.backgroundColor = .systemBackground
            }
        }
    }
}

private extension TorrentListViewController {
    func setup() {
        title = viewModel.title
        navigationItem.largeTitleDisplayMode = .always
        setupCollectionView()
        setupSearch()
    }

    func setupCollectionView() {
        collectionView.allowsMultipleSelectionDuringEditing = true
    }

    func setupSearch() {
        searchVC.showsSearchResultsController = false
        searchVC.searchBar.placeholder = %"common.search"

        searchVC.searchBar.scopeButtonTitles = ["Torrents", "RSS"]
        searchVC.scopeBarActivation = .onSearchActivation

        navigationItem.searchController = searchVC
    }

    func updateSortingMenu(with selected: ViewModel.Sort, reverced: Bool, isGrouped: Bool) {
        sortButton.menu = .init(title: %"list.sort.title", children:
            [
                UIMenu(options: .displayInline, children: ViewModel.Sort.allCases.map { type in UIAction(title: type.name, image: selected == type ? (reverced ? .init(systemName: "chevron.up") : .init(systemName: "chevron.down")) : nil) { [unowned self] _ in
                    if viewModel.sortingType.value == type {
                        viewModel.sortingReverced.value.toggle()
                    } else {
                        viewModel.sortingType.value = type
                        viewModel.sortingReverced.value = false
                    }
                }}),
                UIMenu(options: .displayInline, children:
                    [
                        UIAction(title: %"list.sort.grouped", image: isGrouped ? .init(systemName: "checkmark") : nil) { [unowned self] _ in
                            viewModel.isGroupedByState.value.toggle()
                        }
                    ])
            ])
    }
}

// MARK: - Binding
private extension TorrentListViewController {
    func binding() {
        disposeBag.bind {
            searchVC.isActivePublisher.sink { [unowned self] isActive in
                viewModel.searchPresented = isActive
            }

            viewModel.$filterButtons.removeDuplicates().sink { [unowned self] buttons in
                tagsView.titles = buttons
                guard let filter = viewModel.filter else {
                    tagsView.selectedTagIndex = 0
                    return
                }
                tagsView.selectedTagIndex = (TorrentHandle.State.filterArray.firstIndex(where: { $0 == filter }) ?? 0) + 1
            }

            tagsView.$selectedTagIndex.sink { [unowned self] index in
                viewModel.filter = index <= 0 ? nil : TorrentHandle.State.filterArray[index - 1]
            }

            viewModel.isGroupedByState.removeDuplicates().uiSink { [unowned self] value in
                navigationItem.setBottomPalette(value ? nil : tagsView)
            }

            viewModel.$hasRssNews.uiSink { [unowned self] rssHasNews in
                let rssHasNewsImage: UIImage?
                if #available(iOS 26, *) {
                    rssHasNewsImage = .icRssNew.applyingSymbolConfiguration(.init(paletteColors: [.label, .systemRed]))
                } else {
                    rssHasNewsImage = .icRssNew.withRenderingMode(.alwaysOriginal)
                }
                rssButton.primaryAction = .init(title: %"rssfeed", image: rssHasNews ? rssHasNewsImage : .icRss, handler: { [unowned self] _ in
                    viewModel.showRss()
                })
            }

            collectionView.$selectedIndexPaths.uiSink { [unowned self] indexPaths in
                let torrentHandles = indexPaths.compactMap { (viewModel.sections[$0.section].items[$0.item] as? TorrentListItemViewModel)?.torrentHandle }

                playButton.isEnabled = torrentHandles.contains(where: { $0.snapshot.isPaused })
                pauseButton.isEnabled = torrentHandles.contains(where: { !$0.snapshot.isPaused })
                rehashButton.isEnabled = !torrentHandles.isEmpty
                deleteButton.isEnabled = !torrentHandles.isEmpty
            }

            preferencesButton.tapPublisher.uiSink { [unowned self] _ in
                viewModel.preferencesAction()
            }

            viewModel.sortingType.combineLatest(viewModel.sortingReverced, viewModel.isGroupedByState).uiSink { [unowned self] type, reverced, grouped in
                updateSortingMenu(with: type, reverced: reverced, isGrouped: grouped)
            }

            searchVC.searchBar.selectedScopeButtonIndexDidChangePublisher.uiSink { [unowned self] scopeIndex in
                searchVC.showsSearchResultsController = scopeIndex == 1
            }

            if #available(iOS 17.0, *) {
                viewModel.emptyContentType.uiSink { [unowned self] emptyType in
                    switch emptyType {
                    case .noData:
                        var config = UIContentUnavailableConfiguration.empty()
                        config.image = .init(systemName: "fireworks")
                        config.text = %"list.empty.nodata.title"
                        config.secondaryText = %"list.empty.nodata.subtitle"
                        contentUnavailableConfiguration = config
                    case .badSearch:
                        contentUnavailableConfiguration = UIContentUnavailableConfiguration.search()
                    case .badFilter(let filter):
                        var configuration = UIContentUnavailableConfiguration.empty()
                        configuration.image = .init(systemName: "line.3.horizontal.decrease")
                        configuration.text = %"list.empty.filter.title-\(filter.name)"
                        configuration.secondaryText = %"list.empty.filter.subtitle"
                        contentUnavailableConfiguration = configuration
                    case nil:
                        contentUnavailableConfiguration = nil
                    }
                }
            }
        }
    }
}

private extension TorrentListViewController {
    class Delegates: DelegateObject<TorrentListViewController>, UIDocumentPickerDelegate {
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.viewModel.addTorrent(by: url)
        }
    }

    func makeDocumentPicker() -> UIViewController {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.init(importedAs: "com.bittorrent.torrent")], asCopy: true)
        documentPicker.delegate = delegates
        documentPicker.allowsMultipleSelection = false
        documentPicker.shouldShowFileExtensions = true
        return documentPicker
    }

    func makeMagnetAlert() -> UIAlertController {
        let alert = UIAlertController(title: %"list.add.magnet.title", message: %"list.add.magnet.message", preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = %"list.add.magnet.placeholder"
        }

        alert.addAction(.init(title: %"common.cancel", style: .cancel))
        alert.addAction(.init(title: %"common.ok", style: .default) { [unowned self] _ in
            guard let text = alert.textFields?.first?.text,
                  let url = URL(string: text),
                  let magnet = MagnetURI(with: url)
            else {
                let alert = UIAlertController(title: %"common.error", message: %"list.add.magnet.error", preferredStyle: .alert)
                alert.addAction(.init(title: %"common.close", style: .cancel))
                present(alert, animated: true)
                return
            }

            guard !TorrentService.shared.checkTorrentExists(with: magnet.infoHashes) else {
                let alert = UIAlertController(title: %"addTorrent.exists", message: %"addTorrent.\(magnet.infoHashes.best.hex)_exists", preferredStyle: .alert)
                alert.addAction(.init(title: %"common.close", style: .cancel))
                present(alert, animated: true)
                return
            }

            TorrentService.shared.addTorrent(by: magnet)
        })
        return alert
    }

    func makeUrlAlert() -> UIAlertController {
        let alert = UIAlertController(title: %"list.add.url.title", message: %"list.add.url.message", preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = %"list.add.url.placeholder"
        }

        alert.addAction(.init(title: %"common.cancel", style: .cancel))
        alert.addAction(.init(title: %"common.ok", style: .default) { [unowned self] _ in
            Task {
                guard let text = alert.textFields?.first?.text,
                      let url = URL(string: text),
                      let torrentFile = await TorrentFile(remote: url)
                else {
                    let alert = UIAlertController(title: %"common.error", message: %"list.add.url.error", preferredStyle: .alert)
                    alert.addAction(.init(title: %"common.close", style: .cancel))
                    present(alert, animated: true)
                    return
                }

                TorrentAddViewModel.present(with: torrentFile, from: self)
            }
        })
        return alert
    }

    static func makeTagsView() -> TagsView {
        let tagsView = TagsView()
        tagsView.translatesAutoresizingMaskIntoConstraints = false
        return tagsView
    }
}

private extension TorrentListViewController {
    var fixedSpacing: UIBarButtonItem? {
        if #available(iOS 26, *) {
            return nil
        } else {
            return UIBarButtonItem.fixedSpace(44)
        }
    }
}

private extension TorrentListViewModel.Sort {
    var name: String {
        switch self {
        case .alphabetically:
            return %"list.sort.name"
        case .creationDate:
            return %"list.sort.creationDate"
        case .addedDate:
            return %"list.sort.addedDate"
        case .size:
            return %"list.sort.size"
        }
    }
}

extension TorrentHandle.State {
    static var filterArray: [TorrentHandle.State] {
        [
            .finished,
            .downloading,
            .seeding,
            .paused,
            .checkingFiles,
            .downloadingMetadata,
            .checkingResumeData,

            // Custom state for storage error
            .storageError
        ]
    }
}
