//
//  BackgroundService.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 05/04/2024.
//

import Foundation
import Combine
import LibTorrent

@MainActor
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

@MainActor
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
        isRunningPublisher = false
        impl.stop()
    }

    func prepare() async -> Bool {
        await impl.prepare()
    }

    func applyMode(_ mode: Mode) async -> Bool {
        let request = UUID()
        modeRequest = request
        let replacement: BackgroundServiceProtocol
        switch mode {
        case .audio:
            replacement = AudioBackgroundService()
        case .location:
            replacement = LocationBackgroundService()
        }
        // Stop the old implementation before releasing its player or location
        // manager. Keep the replacement alive across the authorization prompt.
        impl.stop()
        isRunningPublisher = false
        impl = replacement
        let prepared = await replacement.prepare()
        // An older authorization response must not reset a newer mode choice.
        guard modeRequest == request else { return true }
        return prepared
    }

    private var modeRequest: UUID?
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
