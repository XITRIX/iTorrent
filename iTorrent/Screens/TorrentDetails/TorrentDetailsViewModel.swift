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

    private let progressModel = TorrentDetailProgressCellViewModel(title: "Progress")

    private let hashModel = DetailCellViewModel(title: "Hash", spacer: 80)
    private let hashModelV2 = DetailCellViewModel(title: "Hash v2", spacer: 80)
    private let creatorModel = DetailCellViewModel(title: "Creator", spacer: 80)
    private let createdModel = DetailCellViewModel(title: "Created")

    private let selectedModel = DetailCellViewModel(title: "Selected/Total")
    private let completedModel = DetailCellViewModel(title: "Completed")
    private let selectedProgressModel = DetailCellViewModel(title: "Progress Selected/Total")
    private let downloadedModel = DetailCellViewModel(title: "Downloaded")
    private let uploadedModel = DetailCellViewModel(title: "Uploaded")
    private let seedersModel = DetailCellViewModel(title: "Seeders")
    private let leechersModel = DetailCellViewModel(title: "Leechers")
}

extension TorrentDetailsViewModel {
    func resume() {
        torrentHandle.resume()
    }

    func pause() {
        torrentHandle.pause()
    }

    func rehash() {
        alert(title: "Torrent rehash", message: "This action will recheckthe state of all downloaded files", actions: [
            .init(title: "Cancel", style: .cancel),
            .init(title: "Rehash", style: .destructive, action: { [unowned self] in
                torrentHandle.rehash()
            })
        ])
    }
}

private extension TorrentDetailsViewModel {
    func reload() {
        stateModel.detail = "\(torrentHandle.friendlyState.name)"// "\(torrentHandle.state.rawValue) | \(torrentHandle.isPaused ? "Paused" : "Running")"

        downloadModel.detail = "\(torrentHandle.downloadRate.bitrateToHumanReadable)/s"
        uploadModel.detail = "\(torrentHandle.uploadRate.bitrateToHumanReadable)/s"
        timeLeftModel.detail = torrentHandle.timeRemains

        progressModel.progress = torrentHandle.progress

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

        selectedModel.detail = "\(torrentHandle.totalWanted.bitrateToHumanReadable) / \(torrentHandle.total.bitrateToHumanReadable)"
        completedModel.detail = "\(torrentHandle.totalDone.bitrateToHumanReadable)"
        selectedProgressModel.detail = "\(String(format: "%.2f", torrentHandle.progress * 100))% / \(String(format: "%.2f", torrentHandle.progressWanted * 100))%"
        downloadedModel.detail = "\(torrentHandle.totalDownload.bitrateToHumanReadable)"
        uploadedModel.detail = "\(torrentHandle.totalUpload.bitrateToHumanReadable)"
        seedersModel.detail = "\(torrentHandle.numberOfSeeds)(\(torrentHandle.numberOfTotalSeeds))"
        leechersModel.detail = "\(torrentHandle.numberOfLeechers)(\(torrentHandle.numberOfTotalLeechers))"

        /// ------

        var sections: [MvvmCollectionSectionModel] = []

        sections.append(.init(id: "state") {
            stateModel
        })

        sections.append(.init(id: "speed", header: "Speed") {
            downloadModel
            uploadModel
            
            if !torrentHandle.isPaused {
                timeLeftModel
            }
        })

        sections.append(.init(id: "download", header: "Downloading") {
            progressModel
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

        sections.append(.init(id: "transfer", header: "Transfer") {
            selectedModel
            completedModel
            selectedProgressModel
            downloadedModel
            uploadedModel
            seedersModel
            leechersModel
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
