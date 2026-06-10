//
//  TorrentListViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 29/10/2023.
//

import Combine
import LibTorrent
import MvvmFoundation
import SwiftData

enum EmptyType {
    case noData
    case badSearch(String)
    case badFilter(TorrentSession.Handle.State)
}

extension TorrentListViewModel {
    enum Sort: CaseIterable, Codable {
        case alphabetically
        case creationDate
        case addedDate
        case size
    }
}

class TorrentListViewModel: BaseViewModel {
    @Published var sections: [MvvmCollectionSectionModel] = []
    @Published var searchPresented: Bool = false
    @Published var searchQuery: String = ""
    @Published var title: String = ""
    @Published var hasRssNews: Bool = false
    @Published var filterButtons: [String] = []
    @Published var filter: TorrentSession.Handle.State?

    lazy var rssSearchViewModel: RssSearchViewModel = {
        let vm = RssSearchViewModel()
        vm.setNavigationService { [weak self] in
            self?.navigationService?()
        }
        return vm
    }()

    var isGroupedByState: CurrentValueRelay<Bool> {
        PreferencesStorage.shared.$torrentListGroupedByState
    }

    var sortingType: CurrentValueRelay<Sort> {
        PreferencesStorage.shared.$torrentListSortType
    }

    var sortingReverced: CurrentValueRelay<Bool> {
        PreferencesStorage.shared.$torrentListSortReverced
    }

    required init() {
        super.init()
        title = "iTorrent"

        filterButtons = [%"common.all"] + TorrentSession.Handle.State.filterArray.map { $0.name }

//        Task {
//            try await Task.sleep(for: .seconds(0.1))

            let groupsSortingArray = PreferencesStorage.shared.$torrentListGroupsSortingArray
            let torrentSectionChanged = TorrentService.shared.updateNotifier.filter { update in
                update.oldSnapshot.friendlyState != TorrentService.shared.modernHandle(for: update.oldSnapshot.infoHashes)?.currentSnapshot?.friendlyState
            }.map { _ in () }.prepend([()])

            disposeBag.bind {
                rssFeedProvider.hasNewsPublisher.sink { [unowned self] value in
                    hasRssNews = value
                }
            }

            Publishers.combineLatest(
                torrentSectionChanged,
                TorrentService.shared.$modernHandles.map { Array($0.values) },
                $searchQuery,
                $searchPresented,
                sortingType,
                sortingReverced,
                isGroupedByState,
                groupsSortingArray,
                $filter
            ) { _, torrentHandles, searchQuery, searchPresented, sortingType, sortingReverced, isGrouping, sortingArray, filter in
                var torrentHandles = torrentHandles
                if !searchQuery.isEmpty {
                    torrentHandles = torrentHandles.filter {
                        Self.searchFilter($0.currentSnapshot?.name ?? "", by: searchQuery)
                    }
                }
                return (torrentHandles.sorted(by: sortingType, reverced: sortingReverced), isGrouping, sortingArray, filter, searchPresented)
            }
            .map { [unowned self] torrents, isGrouping, sortingArray, filter, searchPresented in
                if isGrouping {
                    return makeGroupedSections(with: torrents, by: sortingArray)
                } else {
                    updateFilterNames()
                    return makeUngroupedSection(with: torrents, filter: filter, searchPresented: searchPresented)
                }
            }.assign(to: &$sections)
            $searchQuery.assign(to: &rssSearchViewModel.$searchQuery)
//        }
    }

    static func searchFilter(_ text: String, by query: String) -> Bool {
        query.split(separator: " ").allSatisfy { text.localizedCaseInsensitiveContains($0) }
    }
    @Injected private var rssFeedProvider: RssFeedProvider
}

extension TorrentListViewModel {
    var emptyContentType: AnyPublisher<EmptyType?, Never> {
        Publishers.combineLatest($sections, $searchQuery, $filter) { sections, searchQuery, filter in
            if sections.isEmpty || sections.allSatisfy({ $0.items.isEmpty }) {
                if !searchQuery.isEmpty { return EmptyType.badSearch(searchQuery) }
                if let filter { return EmptyType.badFilter(filter) }
                return EmptyType.noData
            }
            return nil
        }.eraseToAnyPublisher()
    }

    func preferencesAction() {
        navigate(to: PreferencesViewModel.self, by: .show)
    }

    func showRss() {
        navigate(to: RssListViewModel.self, by: .show)
    }

    func addTorrent(by url: URL) {
        guard let navigationService = navigationService?() else { return }
        TorrentAddViewModel.present(with: url, from: navigationService)
    }

    func resumeAllSelected(at indexPaths: [IndexPath]) {
        let torrentModels = indexPaths.compactMap { sections[$0.section].items[$0.item] as? TorrentListItemViewModel }
        torrentModels.forEach { model in
            guard model.snapshot.canResume else { return }
            Task { await model.torrentHandle.resume() }
        }
    }

    func pauseAllSelected(at indexPaths: [IndexPath]) {
        let torrentModels = indexPaths.compactMap { sections[$0.section].items[$0.item] as? TorrentListItemViewModel }
        torrentModels.forEach { model in
            Task { await model.torrentHandle.pause() }
        }
    }

    func rehashAllSelected(at indexPaths: [IndexPath]) {
        let torrentModels = indexPaths.compactMap { sections[$0.section].items[$0.item] as? TorrentListItemViewModel }

        alert(title: %"details.rehash.title", message: %"details.rehash.message", actions: [
            .init(title: %"common.cancel", style: .cancel),
            .init(title: %"details.rehash.action", style: .destructive, isPrimary: true, action: {
                torrentModels.forEach { model in
                    Task { await model.torrentHandle.rehash() }
                }
            })
        ])
    }

    func deleteAllSelected(at indexPaths: [IndexPath]) {
        let torrentModels = indexPaths.compactMap { sections[$0.section].items[$0.item] as? TorrentListItemViewModel }
        let message = torrentModels.map { $0.snapshot.name }.joined(separator: "\n\n")

        alert(title: %"torrent.remove.title", message: message, actions: [
            .init(title: %"torrent.remove.action.dropData", style: .destructive, action: {
                torrentModels.forEach { torrentModel in
                    TorrentService.shared.removeTorrent(by: torrentModel.torrentHandle.infoHashes, deleteFiles: true)
                }
            }),
            .init(title: %"torrent.remove.action.keepData", style: .default, action: {
                torrentModels.forEach { torrentModel in
                    TorrentService.shared.removeTorrent(by: torrentModel.torrentHandle.infoHashes, deleteFiles: false)
                }
            }),
            .init(title: %"common.cancel", style: .cancel, isPrimary: true)
        ])
    }

    func removeTorrent(_ torrentHandle: TorrentSession.Handle) {
        let snapshot = torrentHandle.currentSnapshot

        alert(title: %"torrent.remove.title", message: snapshot?.name ?? "", actions: [
            .init(title: %"torrent.remove.action.dropData", style: .destructive, action: {
                TorrentService.shared.removeTorrent(by: torrentHandle.infoHashes, deleteFiles: true)
            }),
            .init(title: %"torrent.remove.action.keepData", style: .default, action: {
                TorrentService.shared.removeTorrent(by: torrentHandle.infoHashes, deleteFiles: false)
            }),
            .init(title: %"common.cancel", style: .cancel, isPrimary: true)
        ])
    }

    func updateFilterNames() {
        let handles = Array(TorrentService.shared.modernHandles.values)
        let dictionary = [TorrentSession.Handle.State: [TorrentSession.Handle]](grouping: handles, by: { handle in
            handle.currentSnapshot?.friendlyState ?? .paused
        })

        let allCount = handles.count
        filterButtons = ["\(%"common.all")\(allCount > 0 ? " (\(allCount))" : "")"] + TorrentSession.Handle.State.filterArray.map { "\($0.name)\(dictionary[$0].map { " (\($0.count))" } ?? "")" }
    }
}

private extension TorrentListViewModel {
    func makeUngroupedSection(with torrents: [TorrentSession.Handle], filter: TorrentSession.Handle.State?, searchPresented: Bool) -> [MvvmCollectionSectionModel] {
        [.init(id: "torrents", style: .platformPlain, showsSeparators: true, items: torrents.filter { torrent in
            guard filter != nil && !searchPresented else { return true }
            return torrent.currentSnapshot?.friendlyState == filter
        }.map {
            let vm = TorrentListItemViewModel(with: $0)
            vm.setNavigationService { [weak self] in self?.navigationService?() }
            return vm
        })]
    }

    static func getStateGroupintIndex(_ state: TorrentSession.Handle.State, from sortingArray: [TorrentSession.Handle.State]) -> Int {
        let index = sortingArray.firstIndex(of: state)
        assert(index != nil, "SortingArray missed \(state) state. SortingArray should contain all possible states of \(TorrentSession.Handle.State.self)")
        return index ?? -1
    }

    func makeGroupedSections(with torrents: [TorrentSession.Handle], by sortingArray: [TorrentSession.Handle.State]) -> [MvvmCollectionSectionModel] {
        let dictionary = [TorrentSession.Handle.State: [TorrentSession.Handle]](grouping: torrents, by: {
            $0.currentSnapshot?.friendlyState ?? .paused
        })
        return dictionary.sorted { Self.getStateGroupintIndex($0.key, from: sortingArray) < Self.getStateGroupintIndex($1.key, from: sortingArray) }.map { section in
            MvvmCollectionSectionModel(id: section.key.name, header: section.key.name, style: .platformPlain, items: section.value.map {
                let vm = TorrentListItemViewModel(with: $0)
                vm.setNavigationService { [weak self] in self?.navigationService?() }
                return vm
            })
        }
    }
}

private extension Array where Element == TorrentSession.Handle {
    func sorted(by type: TorrentListViewModel.Sort, reverced: Bool) -> [Element] {
        let res = filter { $0.currentSnapshot?.isValid == true }.sorted { first, second in
            let firstSnapshot = first.currentSnapshot
            let secondSnapshot = second.currentSnapshot

            switch type {
            case .alphabetically:
                return (firstSnapshot?.name ?? "").localizedCaseInsensitiveCompare(secondSnapshot?.name ?? "") == .orderedAscending
            case .creationDate:
                return firstSnapshot?.creationDate ?? Date() > secondSnapshot?.creationDate ?? Date()
            case .addedDate:
                return first.metadata.dateAdded > second.metadata.dateAdded
            case .size:
                return (firstSnapshot?.totalWanted ?? 0) > (secondSnapshot?.totalWanted ?? 0)
            }
        }

        return reverced ? res.reversed() : res
    }
}
