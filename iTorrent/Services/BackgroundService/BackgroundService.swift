//
//  BackgroundService.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 05/04/2024.
//

import Foundation
import Combine
import LibTorrent

protocol BackgroundServiceProtocol {
    var isRunning: Bool { get }
    func start() -> Bool
    func stop()
    func prepare() async -> Bool
}

extension BackgroundService {
    enum Mode: Codable {
        case audio
        case location
    }
}

class BackgroundService: BackgroundServiceProtocol {
    @Published var isRunningPublisher: Bool = false

    public static let shared = BackgroundService()

    var isRunning: Bool { impl.isRunning }

    @discardableResult
    func start() -> Bool {
        let res = impl.start()
        isRunningPublisher = res
        return res
    }

    func stop() {
        guard isRunning else { return }
        isRunningPublisher = false
        impl.stop()
    }

    func prepare() async -> Bool {
        await impl.prepare()
    }

    func applyMode(_ mode: Mode) async -> Bool {
        switch mode {
        case .audio:
            impl = AudioBackgroundService()
        case .location:
            impl = LocationBackgroundService()
        }
        return await impl.prepare()
    }

    private var impl: BackgroundServiceProtocol = AudioBackgroundService()
}

// MARK: Backgroud requirements
extension BackgroundService {
    static var isBackgroundNeeded: Bool {
        TorrentService.shared.torrents.values.contains(where: { $0.snapshot.needBackground })
    }
}

extension TorrentHandle.Snapshot {
    var needBackground: Bool {
        false
            || friendlyState == .checkingFiles
            || friendlyState == .checkingResumeData
            || friendlyState == .downloading
            || friendlyState == .downloadingMetadata
            || (friendlyState == .seeding && PreferencesStorage.shared.isBackgroundSeedingEnabled)
    }
}
