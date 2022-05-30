//
//  TorrentSettingsViewModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 14.05.2022.
//

import MVVMFoundation
import ReactiveKit

class TorrentSettingsViewModel: MvvmViewModel {
    typealias Switch = TorrentSettingsSwitchViewModel
    typealias Action = TorrentSettingsActionViewModel

    private let preferences: PropertyStorage = MVVM.resolve()
    @Bindable var sections = [SectionModel<TableCellRepresentable>]()
    let deselectCell = PassthroughSubject<Void, Never>()

    override func setup() {
        super.setup()

        title.value = "Preferences"

        // MARK: - Status Section
        let allocateStorage = Switch(title: "Allocate storage")

        bind(in: bag) {
            preferences.$preallocationStorage <=> allocateStorage.$value
        }

        sections.append(SectionModel<TableCellRepresentable>(header: "Storage", items: [allocateStorage]))

        // MARK: - Background Section
        let allowBackgroud = Switch(title: "Enable")
        let allowBackgroudSeeding = Switch(title: "Allow seeding")

        bind(in: bag) {
            preferences.$backgroundProcessing <=> allowBackgroud.$value
            preferences.$preallocationStorage <=> allowBackgroudSeeding.$value
        }

        sections.append(SectionModel<TableCellRepresentable>(header: "Background downloading", items: [allowBackgroud, allowBackgroudSeeding]))

        // MARK: - Queue Limits Section
        let queueActiveLimit = Action(title: "Active torrents")
        let queueDownloadingLimit = Action(title: "Downloading torrents")
        let queueUploadingLimit = Action(title: "Uploading torrents")

        bind(in: bag) {
            preferences.$maxActiveTorrents.map { "\($0)" } => queueActiveLimit.$detail
            preferences.$maxDownloadingTorrents.map { "\($0)" } => queueDownloadingLimit.$detail
            preferences.$maxUploadingTorrents.map { "\($0)" } => queueUploadingLimit.$detail
            
            queueActiveLimit.action.observeNext { [unowned self] _ in
                deselectCell.send()
            }
            queueDownloadingLimit.action.observeNext { [unowned self] _ in
                deselectCell.send()
            }
            queueUploadingLimit.action.observeNext { [unowned self] _ in
                deselectCell.send()
            }
        }

        sections.append(SectionModel<TableCellRepresentable>(header: "Torrent queueing limit", items: [queueActiveLimit, queueDownloadingLimit, queueUploadingLimit]))

        // MARK: - Speed Limits Section
        let speedDownloadLimit = Action(title: "Download limit")
        let speedUploadLimit = Action(title: "Upload limit")

        bind(in: bag) {
            preferences.$maxDownloadSpeed.map { Utils.Size.getSpeedLimitText(size: $0) } => speedDownloadLimit.$detail
            preferences.$maxUploadSpeed.map { Utils.Size.getSpeedLimitText(size: $0) } => speedUploadLimit.$detail

            speedDownloadLimit.action.observeNext { [unowned self] _ in
                deselectCell.send()
            }
            speedUploadLimit.action.observeNext { [unowned self] _ in
                deselectCell.send()
            }
        }

        sections.append(SectionModel<TableCellRepresentable>(header: "Speed limitation", items: [speedDownloadLimit, speedUploadLimit]))
    }
}
