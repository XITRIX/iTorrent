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
            torrent.rx.downloadRate.map { "\(ByteCountFormatter.string(fromByteCount: Int64($0), countStyle: .binary))/s" } => downloadSpeed.$detail
            torrent.rx.uploadRate.map { "\(ByteCountFormatter.string(fromByteCount: Int64($0), countStyle: .binary))/s" } => uploadSpeed.$detail
            torrent.rx.updateObserver.map { torrent in
                Utils.Time.downloadingTimeRemainText(speedInBytes: Int64(torrent.downloadRate), fileSize: Int64(torrent.totalWanted), downloadedSize: Int64(torrent.totalWantedDone))
            } => timeRemain.$detail
        }

        sections.append(SectionModel<TableCellRepresentable>(header: "Speed", items: [downloadSpeed, uploadSpeed, timeRemain]))

        // MARK: - Download Section
        let sequential = Switch(title: "Sequential download", value: torrent.isSequential)

        bind(in: bag) {
            sequential.$value => torrent.rx.isSequential
        }

        sections.append(SectionModel<TableCellRepresentable>(header: "Download", items: [sequential]))

        // MARK: - Info
        let hashInfo = Detail(title: "Hash")
        let creatorInfo = Detail(title: "Creator")
        let creationDateInfo = Detail(title: "Created date")

        bind(in: bag) {
            torrent.rx.infoHash => hashInfo.$detail
            torrent.rx.creator => creatorInfo.$detail
            torrent.rx.creationDate.map { $0?.simpleDate() ?? "Unknown" } => creationDateInfo.$detail
        }

        sections.append(SectionModel<TableCellRepresentable>(header: "Info", items: [hashInfo, creatorInfo, creationDateInfo]))

        // MARK: - Progress
        let overallInfo = Detail(title: "Selected/Total")
        let completionInfo = Detail(title: "Compleded")
        let progressInfo = Detail(title: "Progress\nSelected/Total")
        let downloadInfo = Detail(title: "Downloaded")
        let uploadInfo = Detail(title: "Uploaded")
        let seeds = Detail(title: "Seeds")
        let leeches = Detail(title: "Leechers")

        bind(in: bag) {
            combineLatest(torrent.rx.totalWanted, torrent.rx.total).map { "\(Utils.Size.getSizeText(size: $0, decimals: 2)) / \(Utils.Size.getSizeText(size: $1, decimals: 2))" } => overallInfo.$detail
            torrent.rx.totalDone.map { Utils.Size.getSizeText(size: $0, decimals: 2) } => completionInfo.$detail
            combineLatest(torrent.rx.progress, torrent.rx.progressTotal).map { "\(String(format: "%0.2f %%", $0 * 100)) / \(String(format: "%0.2f %%", $1 * 100))" } => progressInfo.$detail
            torrent.rx.totalDownload.map { "\(Utils.Size.getSizeText(size: $0, decimals: 2))" } => downloadInfo.$detail
            torrent.rx.totalUpload.map { "\(Utils.Size.getSizeText(size: $0, decimals: 2))" } => uploadInfo.$detail
            combineLatest(torrent.rx.numberOfSeeds, torrent.rx.numberOfTotalSeeds).map { "\($0.0) (\($0.1))" } => seeds.$detail
            combineLatest(torrent.rx.numberOfLeechers, torrent.rx.numberOfTotalLeechers).map { "\($0.0) (\($0.1))" } => leeches.$detail
        }

        sections.append(SectionModel<TableCellRepresentable>(header: "Progress", items: [overallInfo, completionInfo, progressInfo, downloadInfo, uploadInfo, seeds, leeches]))

        // MARK: - More
        let trackers = Navigation(title: "Trackers")
        let files = Navigation(title: "Files")

        bind(in: bag) {
            trackers.action.observeNext { [unowned self] _ in print("Test") }
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

    func navigateToFiles() {
//        navigate(to: TorrentFilesViewModel.self, prepare: TorrentFilesModel(torrent: torrent))
    }
}
