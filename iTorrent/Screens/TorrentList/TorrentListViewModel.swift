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
    case badFilter(TorrentHandle.State)
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
    @Published var filter: TorrentHandle.State?

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

        filterButtons = [%"common.all"] + TorrentHandle.State.filterArray.map { $0.name }

//        Task {
//            try await Task.sleep(for: .seconds(0.1))

            let groupsSortingArray = PreferencesStorage.shared.$torrentListGroupsSortingArray
            let torrentSectionChanged = TorrentService.shared.updateNotifier.filter { $0.oldSnapshot.friendlyState != $0.handle?.snapshot.friendlyState }.map{_ in ()}.prepend([()])

            disposeBag.bind {
                rssFeedProvider.hasNewsPublisher.sink { [unowned self] value in
                    hasRssNews = value
                }
            }

            Publishers.combineLatest(
                torrentSectionChanged,
                TorrentService.shared.$torrents.map { Array($0.values) },
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
                    torrentHandles = torrentHandles.filter { Self.searchFilter($0.snapshot.name, by: searchQuery) }
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

    @MainActor
    func preferencesAction() {
        navigate(to: PreferencesViewModel.self, by: .show)
    }

    @MainActor
    func showRss() {
        navigate(to: RssListViewModel.self, by: .show)
    }

    @MainActor
    func addTorrent(by url: URL) {
        guard let navigationService = navigationService?() else { return }
        TorrentAddViewModel.present(with: url, from: navigationService)
    }

    func resumeAllSelected(at indexPaths: [IndexPath]) {
        let torrentModels = indexPaths.compactMap { sections[$0.section].items[$0.item] as? TorrentListItemViewModel }
        torrentModels.forEach { 
            guard $0.torrentHandle.snapshot.canResume else { return }
            $0.torrentHandle.resume()
        }
    }

    func pauseAllSelected(at indexPaths: [IndexPath]) {
        let torrentModels = indexPaths.compactMap { sections[$0.section].items[$0.item] as? TorrentListItemViewModel }
        torrentModels.forEach { $0.torrentHandle.pause() }
    }

    @MainActor
    func rehashAllSelected(at indexPaths: [IndexPath]) {
        let torrentModels = indexPaths.compactMap { sections[$0.section].items[$0.item] as? TorrentListItemViewModel }

        alert(title: %"details.rehash.title", message: %"details.rehash.message", actions: [
            .init(title: %"common.cancel", style: .cancel),
            .init(title: %"details.rehash.action", style: .destructive, action: {
                torrentModels.forEach { $0.torrentHandle.rehash() }
            })
        ])
    }

    @MainActor
    func deleteAllSelected(at indexPaths: [IndexPath]) {
        let torrentModels = indexPaths.compactMap { sections[$0.section].items[$0.item] as? TorrentListItemViewModel }
        let message = torrentModels.map { $0.torrentHandle.snapshot.name }.joined(separator: "\n\n")

        alert(title: %"torrent.remove.title", message: message, actions: [
            .init(title: %"torrent.remove.action.dropData", style: .destructive, action: {
                torrentModels.forEach { torrentModel in
                    TorrentService.shared.removeTorrent(by: torrentModel.torrentHandle.snapshot.infoHashes, deleteFiles: true)
                }
            }),
            .init(title: %"torrent.remove.action.keepData", style: .default, action: {
                torrentModels.forEach { torrentModel in
                    TorrentService.shared.removeTorrent(by: torrentModel.torrentHandle.snapshot.infoHashes, deleteFiles: false)
                }
            }),
            .init(title: %"common.cancel", style: .cancel)
        ])
    }

    @MainActor
    func removeTorrent(_ torrentHandle: TorrentHandle) {
        alert(title: %"torrent.remove.title", message: torrentHandle.snapshot.name, actions: [
            .init(title: %"torrent.remove.action.dropData", style: .destructive, action: {
                TorrentService.shared.removeTorrent(by: torrentHandle.snapshot.infoHashes, deleteFiles: true)
            }),
            .init(title: %"torrent.remove.action.keepData", style: .default, action: {
                TorrentService.shared.removeTorrent(by: torrentHandle.snapshot.infoHashes, deleteFiles: false)
            }),
            .init(title: %"common.cancel", style: .cancel)
        ])
    }

    func updateFilterNames() {
        let dictionary = [TorrentHandle.State: [TorrentHandle]](grouping: TorrentService.shared.torrents.values, by: \.snapshot.friendlyState)

        let allCount = TorrentService.shared.torrents.values.count
        filterButtons = ["\(%"common.all")\(allCount > 0 ? " (\(TorrentService.shared.torrents.values.count))" : "")"] + TorrentHandle.State.filterArray.map { "\($0.name)\(dictionary[$0].map { " (\($0.count))" } ?? "")" }
    }
}

private extension TorrentListViewModel {
    func makeUngroupedSection(with torrents: [TorrentHandle], filter: TorrentHandle.State?, searchPresented: Bool) -> [MvvmCollectionSectionModel] {
        [.init(id: "torrents", style: .platformPlain, showsSeparators: true, items: torrents.filter { torrent in
            guard filter != nil && !searchPresented else { return true }
            return torrent.snapshot.friendlyState == filter
        }.map {
            let vm = TorrentListItemViewModel(with: $0)
            vm.setNavigationService { [weak self] in self?.navigationService?() }
            return vm
        })]
    }

    static func getStateGroupintIndex(_ state: TorrentHandle.State, from sortingArray: [TorrentHandle.State]) -> Int {
        let index = sortingArray.firstIndex(of: state)
        assert(index != nil, "SortingArray missed \(state) state. SortingArray should contain all possible states of \(TorrentHandle.State.self)")
        return index ?? -1
    }

    func makeGroupedSections(with torrents: [TorrentHandle], by sortingArray: [TorrentHandle.State]) -> [MvvmCollectionSectionModel] {
        let dictionary = [TorrentHandle.State: [TorrentHandle]](grouping: torrents, by: \.snapshot.friendlyState)
        return dictionary.sorted { Self.getStateGroupintIndex($0.key, from: sortingArray) < Self.getStateGroupintIndex($1.key, from: sortingArray) }.map { section in
            MvvmCollectionSectionModel(id: section.key.name, header: section.key.name, style: .platformPlain, items: section.value.map {
                let vm = TorrentListItemViewModel(with: $0)
                vm.setNavigationService { [weak self] in self?.navigationService?() }
                return vm
            })
        }
    }
}

private extension Array where Element == TorrentHandle {
    func sorted(by type: TorrentListViewModel.Sort, reverced: Bool) -> [Element] {
        let res = filter(\.snapshot.isValid).sorted { first, second in
            switch type {
            case .alphabetically:
                return first.snapshot.name.localizedCaseInsensitiveCompare(second.snapshot.name) == .orderedAscending
            case .creationDate:
                return first.snapshot.creationDate ?? Date() > second.snapshot.creationDate ?? Date()
            case .addedDate:
                return first.metadata.dateAdded > second.metadata.dateAdded
            case .size:
                return first.snapshot.totalWanted > second.snapshot.totalWanted
            }
        }

        return reverced ? res.reversed() : res
    }
}
