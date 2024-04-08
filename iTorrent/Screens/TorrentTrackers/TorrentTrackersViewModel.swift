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

class TorrentTrackersViewModel: BaseViewModelWith<TorrentHandle> {
    private var torrentHandle: TorrentHandle!
    private var trackers: [TrackerCellViewModel] = []

    @Published var sections: [MvvmCollectionSectionModel] = []
    @Published var selectedIndexPaths: [IndexPath] = []

    var isRemoveAvailable: AnyPublisher<Bool, Never> {
        $selectedIndexPaths.map { !$0.isEmpty }
            .eraseToAnyPublisher()
    }

    override func prepare(with model: TorrentHandle) {
        torrentHandle = model
        disposeBag.bind {
            torrentHandle.updatePublisher.sink { [unowned self] _ in
                reload()
            }
        }
        reload()
    }
}

extension TorrentTrackersViewModel {
    func addTrackers() {
        #if !os(visionOS)
        textMultilineInput(title: %"trackers.add.title", message: %"trackers.add.message", placeholder: "http://x.x.x.x:8080/announce", accept: %"common.add") { [unowned self] result in
            guard let result else { return }
            result.components(separatedBy: .newlines).forEach { urlString in
                guard let url = URL(string: urlString) else { return }
                torrentHandle.addTracker(url.absoluteString)
                reload()
            }
        }
        #else
        textInput(title: %"trackers.add.title.single", message: %"trackers.add.message.single", placeholder: "http://x.x.x.x:8080/announce", cancel: %"common.cancel", accept: %"common.add") { [unowned self] result in
            guard let url = URL(string: result ?? "") else { return }
            torrentHandle.addTracker(url.absoluteString)
            reload()
        }
        #endif
    }

    func removeSelected() {
        alert(title: %"trackers.remove.title", actions: [
            .init(title: %"common.delete", style: .destructive, action: { [unowned self] in
                let urls = selectedIndexPaths.compactMap { indexPath in
                    assert(indexPath.section == 0)
                    return trackers[indexPath.item].url
                }

                torrentHandle.removeTrackers(urls)
                reload()
            }),
            .init(title: %"common.cancel", style: .cancel)
        ])
    }
}

private extension TorrentTrackersViewModel {
    func reload() {
        var sections: [MvvmCollectionSectionModel] = []

        var newTrackers: [TrackerCellViewModel] = []
        var trackerListChanged = false
        for tracker in torrentHandle.trackers {
            if let oldTracker = trackers.first(where: { $0.url == tracker.trackerUrl }) {
                oldTracker.update(with: tracker)
                newTrackers.append(oldTracker)
            } else {
                let model = TrackerCellViewModel(with: tracker)
                model.longPressAction = { [unowned self] in
                    UIPasteboard.general.string = tracker.trackerUrl
                    alertWithTimer(message: "Tracker's URL copied to clipboard!")
                }
                newTrackers.append(model)
                trackerListChanged = true
            }
        }

        if trackerListChanged || trackers.count != newTrackers.count {
            sections.append(.init(id: "trackers", style: .plain, items: newTrackers))
            self.sections = sections
        }

        trackers = newTrackers
    }

//    func isValidTrackerURL(_ url: String) -> Bool {
//        // Regular expression pattern to validate a tracker URL
//        let scheme              = #"https?|udp|ftp|torrent|magnet|ws|wss"#
//        let port                = #":[0-9]+"#
//        let ipv4_addr_domain    = #"[0-9A-Za-z.-]+"#                       // ipv4 addr or domain names
//        let ipv6_addr           = #"\[?[0-9A-Fa-f:]+\]?"#                  // ipv6 addr
//        let path                = #"(/[A-Za-z0-9.-]+)*"#
//
//        let pattern = "^(\(scheme))://(\(ipv4_addr_domain)|\(ipv6_addr))(\(port))?\(path)?$"
//
//        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
//            let range = NSRange(location: 0, length: url.utf16.count)
//            if let _ = regex.firstMatch(in: url, options: [], range: range) {
//                if let _ = URL(string: url) {
//                    return true
//                }
//            }
//        }
//
//        return false
//    }
}
