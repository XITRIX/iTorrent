//
//  TorrentTrackersViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 10/11/2023.
//

import Combine
import LibTorrent
import MvvmFoundation
import UIKit

class TorrentTrackersViewModel: BaseViewModelWith<TorrentSession.Handle> {
    private var torrentHandle: TorrentSession.Handle!
    @Published var trackers: [TrackerCellViewModel] = []

    @Published var sections: [MvvmCollectionSectionModel] = []
    @Published var selectedIndexPaths: [IndexPath] = []

    @Injected var trackersListService: TrackersListService

    var isRemoveAvailable: AnyPublisher<Bool, Never> {
        $selectedIndexPaths.map { !$0.isEmpty }
            .eraseToAnyPublisher()
    }

    override func prepare(with model: TorrentSession.Handle) {
        torrentHandle = model

        disposeBag.bind {
            torrentHandle.updatePublisher
                .sink { [weak self] _ in
                    self?.reload()
                }
        }

        reload()
    }
}

extension TorrentTrackersViewModel {
    func addTrackers() {
        #if os(visionOS)
        textInput(title: %"trackers.add.title.single", message: %"trackers.add.message.single", placeholder: "http://x.x.x.x:8080/announce", cancel: %"common.cancel", accept: %"common.add") { [handle = torrentHandle] result in
            guard let result, let url = URL(string: result) else { return }
            Task {
                await handle?.addTracker(url.absoluteString)
            }
        }
        #else
        textMultilineInput(title: %"trackers.add.title", message: %"trackers.add.message", placeholder: "http://x.x.x.x:8080/announce", accept: %"common.add") { [handle = torrentHandle] result in
            guard let result else { return }
            let urls = result.components(separatedBy: .newlines)
            Task {
                for urlString in urls {
                    guard let url = URL(string: urlString) else { continue }
                    await handle?.addTracker(url.absoluteString)
                }
            }
        }
        #endif
    }

    func addTrackers(from list: TrackersListService.ListState) {
        let urls = list.trackers
        let handle = torrentHandle
        Task {
            for urlString in urls {
                guard let url = URL(string: urlString) else { continue }
                await handle?.addTracker(url.absoluteString)
            }
        }
    }

    func addAllTrackersFromSourcesList() {
        guard let torrentHandle else { return }
        trackersListService.addAllTrackers(to: torrentHandle)
    }

    func removeSelected() {
        alert(title: %"trackers.remove.title", actions: [
            .init(title: %"common.delete", style: .destructive, action: { [selectedIndexPaths, trackers, handle = torrentHandle] in
                let urls = selectedIndexPaths.compactMap { indexPath in
                    assert(indexPath.section == 0)
                    return trackers[indexPath.item].url
                }

                Task {
                    await handle?.removeTrackers(urls)
                }
            }),
            .init(title: %"common.cancel", style: .cancel, isPrimary: true)
        ])
    }

    func reannounceAll() {
        let handle = torrentHandle
        Task {
            await handle?.forceReannounce()
        }
    }
}

private extension TorrentTrackersViewModel {
    func reload() {
        let handle = torrentHandle
        let currentTrackers = trackers
        let showTrackerCopied: (String) -> Void = { [weak self] trackerURL in
            UIPasteboard.general.string = trackerURL
            self?.alertWithTimer(message: %"trackers.action.copy")
        }

        Task {
            guard let handle, let snapshot = await handle.snapshot() else { return }

            var newTrackers: [TrackerCellViewModel] = []
            var trackerListChanged = false

            for tracker in snapshot.trackers {
                if let oldTracker = currentTrackers.first(where: { $0.url == tracker.trackerURL }) {
                    oldTracker.update(with: tracker)
                    newTrackers.append(oldTracker)
                } else {
                    let model = TrackerCellViewModel(with: tracker)
                    model.longPressAction = { [trackerURL = tracker.trackerURL] in
                        showTrackerCopied(trackerURL)
                    }
                    newTrackers.append(model)
                    trackerListChanged = true
                }
            }

            let finalTrackers = newTrackers
            let shouldReloadSections = trackerListChanged

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if shouldReloadSections || self.trackers.count != finalTrackers.count {
                    self.sections = [.init(id: "trackers", style: .plain, items: finalTrackers.removingDuplicates())]
                }
                self.trackers = finalTrackers
            }
        }
    }
}
