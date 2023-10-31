//
//  TorrentDetailsViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 30/10/2023.
//

import LibTorrent
import MvvmFoundation
import Combine

class TorrentDetailsViewModel: BaseViewModelWith<TorrentHandle> {
    private var torrentHandle: TorrentHandle!

    @Published var sections: [MvvmCollectionSectionModel] = []
    @Published var title: String = ""

    override func prepare(with model: TorrentHandle) {
        torrentHandle = model
        title = model.name

        reload()
        disposeBag.bind {
            torrentHandle.updatePublisher.throttle(for: 0.1, scheduler: DispatchQueue.main, latest: true).sink { [unowned self] _ in
                reload()
            }
        }
    }

    private let stateModel = DetailCellViewModel(title: "State")

    private let downloadModel = DetailCellViewModel(title: "Download")
    private let uploadModel = DetailCellViewModel(title: "Upload")
    private let timeLeftModel = DetailCellViewModel(title: "Time remains")

    private let hashModel = DetailCellViewModel(title: "Hash")
    private let hashModelV2 = DetailCellViewModel(title: "Hash V2")
    private let creatorModel = DetailCellViewModel(title: "Creator")
    private let createdModel = DetailCellViewModel(title: "Created")
}

extension TorrentDetailsViewModel {
    func resume() {
        torrentHandle.resume()
    }

    func pause() {
        torrentHandle.pause()
    }
}

private extension TorrentDetailsViewModel {
    func reload() {
        stateModel.detail = "\(torrentHandle.state.rawValue) | \(torrentHandle.isPaused ? "Paused" : "Running")"
        
        downloadModel.detail = "\(torrentHandle.downloadRate.bitrateToHumanReadable)/s"
        uploadModel.detail = "\(torrentHandle.uploadRate.bitrateToHumanReadable)/s"
        timeLeftModel.detail = torrentHandle.timeRemains

        if torrentHandle.infoHashes.hasV1 {
            hashModel.detail = torrentHandle.infoHashes.v1.hex
        }
        if torrentHandle.infoHashes.hasV2 {
            hashModelV2.detail = torrentHandle.infoHashes.v2.hex
        }
        creatorModel.detail = torrentHandle.creator ?? ""
        if let created = torrentHandle.creationDate {
            let formatter: DateFormatter = {
                let formatter = DateFormatter()
                formatter.dateFormat = "dd/MM/YYYY"
                return formatter
            }()
            createdModel.detail = formatter.string(from: created)
        }

        /// ------

        var sections: [MvvmCollectionSectionModel] = []

        sections.append(.init(id: "state") {
            stateModel
        })

        sections.append(.init(id: "speed", header: "Speed") {
            downloadModel
            uploadModel
            timeLeftModel
        })
//
        sections.append(.init(id: "info", header: "Primary info") {
            if torrentHandle.infoHashes.hasV1 {
                hashModel
            }
            if torrentHandle.infoHashes.hasV2 {
                hashModelV2
            }

            if !creatorModel.detail.isEmpty {
                creatorModel
            }

            if !creatorModel.detail.isEmpty {
                createdModel
            }
        })

        self.sections = sections
    }
}

extension TorrentHandle {
    var timeRemains: String {
        guard downloadRate > 0 else { return "Eternity" }
        return ((totalWanted - totalWantedDone) / downloadRate).timeString
    }
}
