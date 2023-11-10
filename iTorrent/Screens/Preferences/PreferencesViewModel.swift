//
//  PreferencesViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 06/11/2023.
//

import MvvmFoundation
import SwiftUI

class PreferencesViewModel: BaseViewModel {
    let sections = CurrentValueRelay<[MvvmCollectionSectionModel]>([])
    let dismissSelection = PassthroughRelay<Void>()

    required init() {
        super.init()
        reload()
    }

    private let preferences = PreferencesStorage.shared
}

private extension PreferencesViewModel {
    func reload() {
        var sections: [MvvmCollectionSectionModel] = []
        defer { self.sections.send(sections) }

        sections.append(.init(id: "memory", header: "Memory") {
            PRSwitchViewModel(with: .init(title: "Memory allocation", value: preferences.$allocateMemory.binding))
        })

        sections.append(.init(id: "torrentQueueLimits", header: "Torrent queueing limits") {
            PRButtonViewModel(with: .init(title: "Active torrents", value: preferences.$maxActiveTorrents.map { $0 == 0 ? "Unlimited" : "\($0)" }.eraseToAnyPublisher()) { [unowned self] in
                textInput(title: "Active torrents", placeholder: "Unlimited", defaultValue: "\(preferences.maxActiveTorrents)", type: .numberPad) { [unowned self] res in
                    if let res {
                        preferences.maxActiveTorrents = Int(res) ?? 0
                    }
                    dismissSelection.send(())
                }
            })
            PRButtonViewModel(with: .init(title: "Downloading torrents", value: preferences.$maxUploadingTorrents.map { $0 == 0 ? "Unlimited" : "\($0)" }.eraseToAnyPublisher()) { [unowned self] in
                textInput(title: "Downloading torrents", placeholder: "Unlimited", defaultValue: "\(preferences.maxUploadingTorrents)", type: .numberPad) { [unowned self] res in
                    if let res {
                        preferences.maxUploadingTorrents = Int(res) ?? 0
                    }
                    dismissSelection.send(())
                }
            })
            PRButtonViewModel(with: .init(title: "Uploading torrents", value: preferences.$maxUploadingTorrents.map { $0 == 0 ? "Unlimited" : "\($0)" }.eraseToAnyPublisher()) { [unowned self] in
                textInput(title: "Uploading torrents", placeholder: "Unlimited", defaultValue: "\(preferences.maxUploadingTorrents)", type: .numberPad) { [unowned self] res in
                    if let res {
                        preferences.maxUploadingTorrents = Int(res) ?? 0
                    }
                    dismissSelection.send(())
                }
            })
        })

        sections.append(.init(id: "speed limits", header: "Speed limits") {
            PRButtonViewModel(with: .init(title: "Max download speed", value: preferences.$maxDownloadSpeed.map { $0 == 0 ? "Unlimited" : UInt64($0).bitrateToHumanReadable }.eraseToAnyPublisher()) { [unowned self] in
                textInput(title: "Speed in KB/s", placeholder: "Unlimited", defaultValue: "\(preferences.maxDownloadSpeed / 1024)", type: .numberPad) { [unowned self] res in
                    if let res {
                        preferences.maxDownloadSpeed = (UInt(res) ?? 0).multipliedReportingOverflow(by: 1024).partialValue
                    }
                    dismissSelection.send(())
                }
            })
            PRButtonViewModel(with: .init(title: "Max upload speed", value: preferences.$maxUploadSpeed.map { $0 == 0 ? "Unlimited" : UInt64($0).bitrateToHumanReadable }.eraseToAnyPublisher()) { [unowned self] in
                textInput(title: "Speed in KB/s", placeholder: "Unlimited", defaultValue: "\(preferences.maxUploadSpeed / 1024)", type: .numberPad) { [unowned self] res in
                    if let res {
                        preferences.maxUploadSpeed = (UInt(res) ?? 0).multipliedReportingOverflow(by: 1024).partialValue
                    }
                    dismissSelection.send(())
                }
            })
        })
    }
}
