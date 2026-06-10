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

class TorrentDetailsViewModel: BaseCollectionViewModelWith<TorrentSession.Handle> {
    private var torrentHandle: TorrentSession.Handle!

    @Published var title: String = ""
    @Published var isPaused: Bool = false
    @Published var canResume: Bool = false
    @Published var canPause: Bool = false

    @Published private var storageError: Bool = false

    let dismissSignal = PassthroughSubject<Void, Never>()

    override func prepare(with model: TorrentSession.Handle) {
        torrentHandle = model
        title = currentSnapshot.name

        dataUpdate()
        reload()

        disposeBag.bind {
            torrentHandle.updatePublisher
                .sink { [unowned self] _ in
                    dataUpdate()
                }

            torrentHandle.updatePublisher
                .sink { [unowned self] _ in
                    reload()
                }

            torrentHandle.removePublisher
                .sink { [unowned self] _ in
                    dismissSignal.send()
                }

            sequentialModel.$isOn.removeDuplicates().sink { [unowned self] value in
                Task { await torrentHandle.setSequentialDownload(value) }
            }

            firstAndLastModel.$isOn.removeDuplicates().sink { [unowned self] value in
                Task { await torrentHandle.setFirstLastPriorityDownload(value) }
            }

            $storageError.removeDuplicates().sink { [unowned self] error in
                runOnMainThreadIfNeeded { [self] in
                    downloadPathModel.accessories = error ?
                        [
                            .image(.init(systemName: "exclamationmark.triangle.fill"), options: .init(tintColor: .systemRed)),
                        ] :
                        [
                            //                        .popUpMenu(
//                            .init(title: %"details.path.migrate", children: [
//                                UIAction(title: "Default", state: .off) { _ in },
//                                UIAction(title: "Browse", state: .off) { _ in },
//                            ]), options: .init(tintColor: .tintColor)
//                        )
                        ]

                    downloadPathModel.selectAction = nil // error ? nil : {}
                }
            }

            torrentHandle.updatePublisher
                .map { [unowned self] _ in
                    (currentSnapshot.isSequential, currentSnapshot.isFirstLastPiecePriority)
                }
                .removeDuplicates(by: {
                    $0.0 == $1.0 && $0.1 == $1.1
                })
                .sink { [weak self, downloadPrioritiesMenuModel] (_: Bool, _: Bool) in
                guard let self else { return }

                let snapshot = self.currentSnapshot
                downloadPrioritiesMenuModel.value = makeDownloadPriorityValue(isSequential: snapshot.isSequential, isFirstLastPiecePriority: snapshot.isFirstLastPiecePriority)
                downloadPrioritiesMenuModel.menu = .init(options: [], children: [
                    UIAction(title: %"details.downloading.sequential",
                             image: .numbersCapsule,
                             attributes: [.keepsMenuPresented],
                             state: snapshot.isSequential ? .on : .off)
                    { [unowned self] _ in
                        Task { await self.torrentHandle.setSequentialDownload(!self.currentSnapshot.isSequential) }
                    },
                    UIAction(title: %"details.downloading.firstAndLast",
                             image: .arrowLeftAndRightCapsule,
                             attributes: [.keepsMenuPresented],
                             state: snapshot.isFirstLastPiecePriority ? .on : .off)
                    { [unowned self] _ in
                        Task { await self.torrentHandle.setFirstLastPriorityDownload(!self.currentSnapshot.isFirstLastPiecePriority) }
                    },
                ])
            }
        }

        hashModel.longPressAction = { [unowned self] in
            UIPasteboard.general.string = hashModel.detail
            alertWithTimer(message: %"details.copy.hash.title")
        }

        hashModelV2.longPressAction = { [unowned self] in
            UIPasteboard.general.string = hashModelV2.detail
            alertWithTimer(message: %"details.copy.hashV2.title")
        }

        creatorModel.longPressAction = { [unowned self] in
            UIPasteboard.general.string = creatorModel.detail
            alertWithTimer(message: %"details.copy.creator.title")
        }

        commentModel.longPressAction = { [unowned self] in
            UIPasteboard.general.string = commentModel.detail
            alertWithTimer(message: %"details.copy.comment.title")
        }
    }

    private let stateModel = DetailCellViewModel(title: %"details.state")

    private let downloadModel = DetailCellViewModel(title: %"details.speed.download")
    private let uploadModel = DetailCellViewModel(title: %"details.speed.upload")
    private let timeLeftModel = DetailCellViewModel(title: %"details.speed.timeRemains")

    private let sequentialModel = ToggleCellViewModel(title: %"details.downloading.sequential")
    private let firstAndLastModel = ToggleCellViewModel(title: %"details.downloading.firstAndLast")
    private lazy var downloadPrioritiesMenuModel = MenuButtonCellViewModel(with: .init(title: %"details.downloading.downloadPriorities", isBold: true, dismissSelection: { [weak self] in self?.dismissSelection.send() }))
    private let progressModel = TorrentDetailProgressCellViewModel(title: %"details.downloading.progress")

    private let hashModel = DetailCellViewModel(title: %"details.info.hash", spacer: 80)
    private let hashModelV2 = DetailCellViewModel(title: %"details.info.hashV2", spacer: 80)
    private let creatorModel = DetailCellViewModel(title: %"details.info.creator", spacer: 80)
    private let commentModel = DetailCellViewModel(title: %"details.info.comment", spacer: 80)
    private let createdModel = DetailCellViewModel(title: %"details.info.created")
    private let addedModel = DetailCellViewModel(title: %"details.info.added")
    private let downloadPath2Model = DetailCellViewModel(title: "Download Path")

    private let selectedModel = DetailCellViewModel(title: %"details.transfer.selectedTotal")
    private let completedModel = DetailCellViewModel(title: %"details.transfer.completed")
    private let selectedProgressModel = DetailCellViewModel(title: %"details.transfer.progressSelectedTotal")
    private let downloadedModel = DetailCellViewModel(title: %"details.transfer.downloaded")
    private let uploadedModel = DetailCellViewModel(title: %"details.transfer.uploaded")
    private let seedersModel = DetailCellViewModel(title: %"details.transfer.seeders")
    private let leechersModel = DetailCellViewModel(title: %"details.transfer.leechers")

    private lazy var downloadPathModel = PRButtonViewModel(with: .init(title: %"details.path.browse", isBold: true, value: nil))

    private lazy var trackersModel = DetailCellViewModel(title: %"details.actions.trackers") { [unowned self] in
        navigate(to: TorrentTrackersViewModel.self, with: torrentHandle, by: .show)
    }
    private lazy var filesModel = DetailCellViewModel(title: %"details.actions.files") { [unowned self] in
        navigate(to: TorrentFilesViewModel.self, with: .init(torrentHandle: torrentHandle), by: .show)
    }

    @Injected private var torrentService: TorrentService
    @Injected private var preferences: PreferencesStorage
}

extension TorrentDetailsViewModel {
    var shareAvailable: AnyPublisher<Bool, Never> {
        torrentHandle.updatePublisher
            .map { [unowned self] _ in
                !(currentSnapshot.torrentFilePath).isNilOrEmpty
            }
            .prepend(!(currentSnapshot.torrentFilePath).isNilOrEmpty)
            .eraseToAnyPublisher()
    }

    func resume() {
        Task { await torrentHandle.resume() }
    }

    func pause() {
        Task { await torrentHandle.pause() }
    }

    func rehash(from source: MvvmPresentationSource) {
        // If Storage is not available, try to reconnect storage
        if currentSnapshot.friendlyState == .storageError {
            return refreshStorage()
        }

        alert(title: %"details.rehash.title", message: %"details.rehash.message", style: .actionSheet, actions: [
            .init(title: %"common.cancel", style: .cancel),
            .init(title: %"details.rehash.action", style: .destructive, isPrimary: true, action: { [unowned self] in
                Task { await torrentHandle.rehash() }
            }),
        ], sourceView: source)
    }

    func refreshStorage() {
        guard let storage = torrentHandle.storage else { return }
        alert(title: %"details.refreshStorage.title", message: %"details.refreshStorage.message", actions: [
            .init(title: %"common.cancel", style: .cancel),
            .init(title: %"common.continue", style: .default, isPrimary: true, action: { [self] in
                DispatchQueue.global(qos: .userInitiated).async { [self] in
                    guard !torrentService.refreshStorage(storage) else { return }
                    alert(title: %"common.error", message: %"details.refreshStorage.fail.message", actions: [
                        .init(title: %"common.close", style: .cancel, isPrimary: true),
                    ])
                }
            }),
        ])
    }

    func removeTorrent(from source: MvvmPresentationSource) {
        alert(title: %"torrent.remove.title", message: currentSnapshot.name, style: .actionSheet, actions: [
            .init(title: %"torrent.remove.action.dropData", style: .destructive, action: { [unowned self] in
                TorrentService.shared.removeTorrent(by: infoHashes, deleteFiles: true)
            }),
            .init(title: %"torrent.remove.action.keepData", style: .default, action: { [unowned self] in
                TorrentService.shared.removeTorrent(by: infoHashes, deleteFiles: false)
            }),
            .init(title: %"common.cancel", style: .cancel, isPrimary: true),
        ], sourceView: source)
    }

    func shareMagnet() {
        UIPasteboard.general.string = currentSnapshot.magnetLink
        alertWithTimer(message: %"details.share.magnetCopy.result")
    }

    var torrentFilePath: String? {
        currentSnapshot.torrentFilePath
    }

    var infoHashes: TorrentSession.Hashes {
        torrentHandle.infoHashes
    }
}

private extension TorrentDetailsViewModel {
    var currentSnapshot: TorrentSession.Handle.Snapshot {
        guard let snapshot = torrentHandle.currentSnapshot else {
            fatalError("Snapshot should exist for active torrent handle")
        }
        return snapshot
    }

    func dataUpdate() {
        let snapshot = currentSnapshot

        isPaused = snapshot.isPaused
        canResume = snapshot.canResume
        canPause = snapshot.canPause
        storageError = snapshot.friendlyState == .storageError

        stateModel.detail = snapshot.friendlyState.name

        downloadModel.detail = "\(snapshot.downloadRate.bitrateToHumanReadable)/s"
        uploadModel.detail = "\(snapshot.uploadRate.bitrateToHumanReadable)/s"
        timeLeftModel.detail = snapshot.timeRemains

        sequentialModel.isOn = snapshot.isSequential
        firstAndLastModel.isOn = snapshot.isFirstLastPiecePriority
        progressModel.progress = snapshot.progress
        progressModel.segmentedProgress = snapshot.segmentedProgress

        if snapshot.infoHashes.hasV1 {
            hashModel.detail = snapshot.infoHashes.v1.hex
        }
        if snapshot.infoHashes.hasV2 {
            hashModelV2.detail = snapshot.infoHashes.v2.hex
        }
        creatorModel.detail = snapshot.creator ?? ""
        commentModel.detail = snapshot.comment ?? ""

        let formatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/YYYY"
            return formatter
        }()

        if let created = snapshot.creationDate {
            createdModel.detail = formatter.string(from: created)
        }
        addedModel.detail = formatter.string(from: torrentHandle.metadata.dateAdded)

        selectedModel.detail = "\(snapshot.totalWanted.bitrateToHumanReadable) / \(snapshot.total.bitrateToHumanReadable)"
        completedModel.detail = "\(snapshot.totalDone.bitrateToHumanReadable)"
        selectedProgressModel.detail = "\(String(format: "%.2f", snapshot.progress * 100))% / \(String(format: "%.2f", snapshot.progressWanted * 100))%"
        downloadedModel.detail = "\(snapshot.totalDownload.bitrateToHumanReadable)"
        uploadedModel.detail = "\(snapshot.totalUpload.bitrateToHumanReadable)"
        seedersModel.detail = "\(snapshot.numberOfSeeds)(\(snapshot.numberOfTotalSeeds))"
        leechersModel.detail = "\(snapshot.numberOfLeechers)(\(snapshot.numberOfTotalLeechers))"

        downloadPath2Model.detail = snapshot.downloadPath?.path() ?? ""
        downloadPathModel.value = torrentHandle.storage?.name ?? ""

        filesModel.isEnabled = snapshot.friendlyState != .storageError && snapshot.hasMetadata
    }

    func reload() {
        var sections: [MvvmCollectionSectionModel] = []
        defer { self.sections = sections }

        sections.append(.init(id: "state") {
            stateModel
        })

        let snapshot = currentSnapshot

        if !snapshot.isPaused,
           snapshot.friendlyState != .checkingFiles
        {
            sections.append(.init(id: "speed", header: %"details.speed") {
                let isSeeding = snapshot.friendlyState == .seeding
                if !isSeeding {
                    downloadModel
                }
                uploadModel
                if !isSeeding {
                    timeLeftModel
                }
            })
        }

        sections.append(.init(id: "download", header: %"details.downloading") {
//            sequentialModel
//            firstAndLastModel
            downloadPrioritiesMenuModel
            progressModel
        })
//
        sections.append(.init(id: "info", header: %"details.info") {
            if snapshot.infoHashes.hasV1 {
                hashModel
            }
            if snapshot.infoHashes.hasV2 {
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

        sections.append(.init(id: "transfer", header: %"details.transfer") {
            selectedModel
            completedModel
            selectedProgressModel
            downloadedModel
            uploadedModel
            seedersModel
            leechersModel
        })

        if !preferences.storageScopes.isEmpty {
            sections.append(.init(id: "path", header: %"details.path") {
                //            downloadPath2Model
                downloadPathModel
            })
        }

        sections.append(.init(id: "actions", header: %"details.actions") {
            trackersModel
            filesModel
        })
    }

    func makeDownloadPriorityValue(
        isSequential: Bool,
        isFirstLastPiecePriority: Bool
    ) -> NSAttributedString {
        guard isSequential || isFirstLastPiecePriority else {
            return NSAttributedString("None")
        }

        let result = NSMutableAttributedString()

        if isSequential {
            let attachment = NSTextAttachment()
            attachment.image = .numbersCapsule.withRenderingMode(.alwaysTemplate)
            result.append(NSAttributedString(attachment: attachment))
        }

        if isFirstLastPiecePriority {
            if result.length > 0 {
                result.append(NSAttributedString(string: " "))
            }

            let attachment = NSTextAttachment()
            attachment.image = .arrowLeftAndRightCapsule.withRenderingMode(.alwaysTemplate)
            result.append(NSAttributedString(attachment: attachment))
        }

        return NSAttributedString(attributedString: result)
    }
}
