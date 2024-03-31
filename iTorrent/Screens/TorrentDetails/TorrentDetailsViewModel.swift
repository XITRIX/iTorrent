//
//  TorrentDetailsViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 30/10/2023.
//

import Combine
import LibTorrent
import MvvmFoundation
import UIKit

class TorrentDetailsViewModel: BaseViewModelWith<TorrentHandle> {
    private var torrentHandle: TorrentHandle!

    @Published var sections: [MvvmCollectionSectionModel] = []
    @Published var title: String = ""
    @Published var isPaused: Bool = false

    override func prepare(with model: TorrentHandle) {
        torrentHandle = model
        title = model.name

        reload()
        disposeBag.bind {
            torrentHandle.updatePublisher
                .sink { [unowned self] _ in
                    reload()
                }

            sequentialModel.$isOn.sink { [unowned self] value in
                torrentHandle.setSequentialDownload(value)
            }
        }
    }

    private let stateModel = DetailCellViewModel(title: "State")

    private let downloadModel = DetailCellViewModel(title: "Download")
    private let uploadModel = DetailCellViewModel(title: "Upload")
    private let timeLeftModel = DetailCellViewModel(title: "Time remains")

    private let sequentialModel = ToggleCellViewModel(title: "Sequential download")
    private let progressModel = TorrentDetailProgressCellViewModel(title: "Progress")

    private let hashModel = DetailCellViewModel(title: "Hash", spacer: 80)
    private let hashModelV2 = DetailCellViewModel(title: "Hash v2", spacer: 80)
    private let creatorModel = DetailCellViewModel(title: "Creator", spacer: 80)
    private let commentModel = DetailCellViewModel(title: "Comment", spacer: 80)
    private let createdModel = DetailCellViewModel(title: "Created")
    private let addedModel = DetailCellViewModel(title: "Added")

    private let selectedModel = DetailCellViewModel(title: "Selected/Total")
    private let completedModel = DetailCellViewModel(title: "Completed")
    private let selectedProgressModel = DetailCellViewModel(title: "Progress Selected/Total")
    private let downloadedModel = DetailCellViewModel(title: "Downloaded")
    private let uploadedModel = DetailCellViewModel(title: "Uploaded")
    private let seedersModel = DetailCellViewModel(title: "Seeders")
    private let leechersModel = DetailCellViewModel(title: "Leechers")

    private lazy var trackersModel = DetailCellViewModel(title: "Trackers") { [unowned self] in
        navigate(to: TorrentTrackersViewModel.self, with: torrentHandle, by: .show)
    }
    private lazy var filesModel = DetailCellViewModel(title: "Files") { [unowned self] in
        navigate(to: TorrentFilesViewModel.self, with: .init(torrentHandle: torrentHandle), by: .show)
    }
}

extension TorrentDetailsViewModel {
    var shareAvailable: AnyPublisher<Bool, Never> {
        torrentHandle.updatePublisher
            .map { !$0.snapshot.torrentFilePath.isNilOrEmpty }
            .eraseToAnyPublisher()
    }

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

    func shareMagnet() {
        UIPasteboard.general.string = torrentHandle.snapshot.magnetLink
        alertWithTimer(message: "Magnet URL copied into clipboard")
    }

    var torrentFilePath: String? {
        torrentHandle.snapshot.torrentFilePath
    }
}

private extension TorrentDetailsViewModel {
    func reload() {
        isPaused = torrentHandle.snapshot.isPaused
        stateModel.detail = "\(torrentHandle.snapshot.friendlyState.name)" // "\(torrentHandle.snapshot.state.rawValue) | \(torrentHandle.snapshot.isPaused ? "Paused" : "Running")"

        downloadModel.detail = "\(torrentHandle.snapshot.downloadRate.bitrateToHumanReadable)/s"
        uploadModel.detail = "\(torrentHandle.snapshot.uploadRate.bitrateToHumanReadable)/s"
        timeLeftModel.detail = torrentHandle.snapshot.timeRemains

        sequentialModel.isOn = torrentHandle.snapshot.isSequential
        progressModel.progress = torrentHandle.snapshot.progress

        if torrentHandle.snapshot.infoHashes.hasV1 {
            hashModel.detail = torrentHandle.snapshot.infoHashes.v1.hex
        }
        if torrentHandle.snapshot.infoHashes.hasV2 {
            hashModelV2.detail = torrentHandle.snapshot.infoHashes.v2.hex
        }
        creatorModel.detail = torrentHandle.snapshot.creator ?? ""
        commentModel.detail = torrentHandle.snapshot.comment ?? ""

        let formatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/YYYY"
            return formatter
        }()

        if let created = torrentHandle.snapshot.creationDate {
            createdModel.detail = formatter.string(from: created)
        }
        addedModel.detail = formatter.string(from: torrentHandle.metadata.dateAdded)

        selectedModel.detail = "\(torrentHandle.snapshot.totalWanted.bitrateToHumanReadable) / \(torrentHandle.snapshot.total.bitrateToHumanReadable)"
        completedModel.detail = "\(torrentHandle.snapshot.totalDone.bitrateToHumanReadable)"
        selectedProgressModel.detail = "\(String(format: "%.2f", torrentHandle.snapshot.progress * 100))% / \(String(format: "%.2f", torrentHandle.snapshot.progressWanted * 100))%"
        downloadedModel.detail = "\(torrentHandle.snapshot.totalDownload.bitrateToHumanReadable)"
        uploadedModel.detail = "\(torrentHandle.snapshot.totalUpload.bitrateToHumanReadable)"
        seedersModel.detail = "\(torrentHandle.snapshot.numberOfSeeds)(\(torrentHandle.snapshot.numberOfTotalSeeds))"
        leechersModel.detail = "\(torrentHandle.snapshot.numberOfLeechers)(\(torrentHandle.snapshot.numberOfTotalLeechers))"

        /// ------

        var sections: [MvvmCollectionSectionModel] = []

        sections.append(.init(id: "state") {
            stateModel
        })

        if !torrentHandle.snapshot.isPaused {
            sections.append(.init(id: "speed", header: "Speed") {
                downloadModel
                uploadModel
                timeLeftModel
            })
        }

        sections.append(.init(id: "download", header: "Downloading") {
            sequentialModel
            progressModel
        })
//
        sections.append(.init(id: "info", header: "Primary info") {
            if torrentHandle.snapshot.infoHashes.hasV1 {
                hashModel
            }
            if torrentHandle.snapshot.infoHashes.hasV2 {
                hashModelV2
            }

            if !creatorModel.detail.isEmpty {
                creatorModel
            }

            if !commentModel.detail.isEmpty {
                commentModel
            }

            if !creatorModel.detail.isEmpty {
                createdModel
            }
            addedModel
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

        sections.append(.init(id: "actions", header: "Actions") {
            trackersModel
            filesModel
        })

        self.sections = sections
    }
}

extension TorrentHandle.Snapshot {
    var timeRemains: String {
        guard downloadRate > 0 else { return "Eternity" }
        guard totalWanted >= totalWantedDone else { return "Almost done" }
        return ((totalWanted - totalWantedDone) / downloadRate).timeString
    }
}
