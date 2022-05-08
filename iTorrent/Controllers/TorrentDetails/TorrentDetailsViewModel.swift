//
//  TorrentDetailsViewModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 17.04.2022.
//

import MVVMFoundation
import ReactiveKit
import TorrentKit

class TorrentDetailsViewModel: MvvmViewModelWith<TorrentHandle> {
    typealias Progress = TorrentDelailsProgressViewModel
    typealias Detail = TorrentDelailsDetailViewModel
    typealias Switch = TorrentDelailsSwitchViewModel
    typealias Navigation = TorrentDelailsNavigationViewModel

    private var torrent: TorrentHandle!

    @Bindable var sections = [SectionModel<TableCellRepresentable>]()

    override func prepare(with item: MvvmViewModelWith<TorrentHandle>.Model) {
        torrent = item
        configure()
    }

    func configure() {
        title.value = torrent.name

        bind(in: bag) {
            torrent.rx.removedObserver.observeNext(with: { [unowned self] in if $0 { dismissToRoot() } })
        }

        // MARK: - Status Section
        let status = Detail(title: "Status")

        bind(in: bag) {
            torrent.rx.displayState.map { $0.description } => status.$detail
        }

        sections.append(SectionModel<TableCellRepresentable>(items: [status]))

//        // MARK: - Speed Section
        let downloadSpeed = Detail(title: "Download")
        let uploadSpeed = Detail(title: "Upload")
        let timeRemain = Detail(title: "Time remains")

        bind(in: bag) {
            torrent.rx.downloadRate.map { "\(Utils.Size.getSizeText(size: $0))/s" } => downloadSpeed.$detail
            torrent.rx.uploadRate.map { "\(Utils.Size.getSizeText(size: $0))/s" } => uploadSpeed.$detail
            torrent.rx.updateObserver.map { torrent -> String in
                if torrent.isPaused { return "---" }
                return Utils.Time.downloadingTimeRemainText(speedInBytes: Int64(torrent.downloadRate), fileSize: Int64(torrent.totalWanted), downloadedSize: Int64(torrent.totalWantedDone))
            } => timeRemain.$detail
        }

        sections.append(SectionModel<TableCellRepresentable>(header: "Speed", items: [downloadSpeed, uploadSpeed, timeRemain]))

        // MARK: - Download Section
        let sequential = Switch(title: "Sequential download")
        let overallProgress = Progress(title: "Progress")

        bind(in: bag) {
            torrent.rx.isSequential <=> sequential.$value
            torrent.rx.progressTotal => overallProgress.$overallProgress
            torrent.rx.pieces.map { $0.map { $0 ? 1 : 0 } } => overallProgress.$partialProgress
        }

        sections.append(SectionModel<TableCellRepresentable>(header: "Downloading", items: [sequential, overallProgress]))

        // MARK: - Seeding
        let allowSeeding = Switch(title: "Allow seeding")

        bind(in: bag) {
            torrent.rx.allowSeeding <=> allowSeeding.$value
        }

        sections.append(SectionModel<TableCellRepresentable>(header: "Seeding", items: [allowSeeding]))

        // MARK: - Info
        let hashInfo = Detail(title: "Hash")
        let creatorInfo = Detail(title: "Creator")
        let creationDateInfo = Detail(title: "Created on")
        let addedDateInfo = Detail(title: "Added on")

        bind(in: bag) {
            torrent.rx.infoHash => hashInfo.$detail
            torrent.rx.creator => creatorInfo.$detail
            torrent.rx.creationDate.map { $0?.simpleDate() ?? "Unknown" } => creationDateInfo.$detail
            torrent.rx.addedDate.map { $0.simpleDate() } => addedDateInfo.$detail
        }

        sections.append(SectionModel<TableCellRepresentable>(header: "General information", items: [hashInfo, creatorInfo, creationDateInfo, addedDateInfo]))

        // MARK: - Progress
        let overallInfo = Detail(title: "Selected/Total")
        let completionInfo = Detail(title: "Compleded")
        let progressInfo = Detail(title: "Progress\nSelected/Total")
        let downloadInfo = Detail(title: "Downloaded")
        let uploadInfo = Detail(title: "Uploaded")
        let seeds = Detail(title: "Seeds")
        let leeches = Detail(title: "Leechers")

        bind(in: bag) {
            combineLatest(torrent.rx.totalWanted, torrent.rx.total).map { "\(Utils.Size.getSizeText(size: $0)) / \(Utils.Size.getSizeText(size: $1))" } => overallInfo.$detail
            torrent.rx.totalDone.map { Utils.Size.getSizeText(size: $0) } => completionInfo.$detail
            combineLatest(torrent.rx.progress, torrent.rx.progressTotal).map { "\(String(format: "%0.2f %%", $0 * 100)) / \(String(format: "%0.2f %%", $1 * 100))" } => progressInfo.$detail
            torrent.rx.totalDownload.map { "\(Utils.Size.getSizeText(size: $0))" } => downloadInfo.$detail
            torrent.rx.totalUpload.map { "\(Utils.Size.getSizeText(size: $0))" } => uploadInfo.$detail
            combineLatest(torrent.rx.numberOfSeeds, torrent.rx.numberOfTotalSeeds).map { "\($0.0) (\($0.1))" } => seeds.$detail
            combineLatest(torrent.rx.numberOfLeechers, torrent.rx.numberOfTotalLeechers).map { "\($0.0) (\($0.1))" } => leeches.$detail
        }

        sections.append(SectionModel<TableCellRepresentable>(header: "Transfer", items: [overallInfo, completionInfo, progressInfo, downloadInfo, uploadInfo, seeds, leeches]))

        // MARK: - More
        let trackers = Navigation(title: "Trackers")
        let files = Navigation(title: "Files")

        bind(in: bag) {
            trackers.action.observeNext { [unowned self] _ in navigateToTrackers() }
            files.action.observeNext { [unowned self] _ in navigateToFiles() }
        }

        sections.append(SectionModel<TableCellRepresentable>(header: "More", items: [trackers, files]))
    }

    func resume() {
        torrent.resume()
    }

    func pause() {
        torrent.pause()
    }

    func rehash() {
        torrent.rehash()
    }

    func navigateToTrackers() {
        navigate(to: TorrentTrackersListViewModel.self, prepare: torrent)
    }

    func navigateToFiles() {
        navigate(to: TorrentFilesViewModel.self, prepare: TorrentFilesModel(torrent: torrent))
    }

    var canResume: Signal<Bool, Never> {
        torrent.rx.canResume
    }

    var canPause: Signal<Bool, Never> {
        torrent.rx.canPause
    }

    var torrentMagnetLink: String {
        torrent.magnetLink
    }

    var torrentFilePath: String? {
        torrent.torrentFilePath
    }

    func removeTorrent(withFiles: Bool) {
        (MVVM.resolve() as TorrentManager).removeTorrent(torrent, deleteFiles: withFiles)
    }
}
