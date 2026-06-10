//
//  TorrentService.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 29/10/2023.
//

import Combine
@preconcurrency import LibTorrent
import MvvmFoundation
import UIKit

extension TorrentService {
    struct TorrentUpdateModel {
        let oldSnapshot: TorrentSession.Handle.Snapshot
        let handle: TorrentSession.Handle?
    }
}

class TorrentService: @unchecked Sendable, ObservableObject {
    @Published private(set) var modernHandles: [TorrentSession.Hashes: TorrentSession.Handle] = [:]

    let updateNotifier = PassthroughSubject<TorrentUpdateModel, Never>()

    static let shared = TorrentService()
    static var version: String { Version.libtorrentVersion }

    init() { setup() }

    #if os(tvOS)
    static let downloadPath: URL = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    #else
    static let downloadPath: URL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    #endif
    static let torrentPath: URL = downloadPath.appending(path: "config")
    static let fastResumePath: URL = downloadPath.appending(path: "config")
    static let metadataPath: URL = downloadPath.appending(path: "config")

    private lazy var session: LegacyTorrentSessionBridge = {
        configureOpenSSLCerts()
        print("Working directory: \(Self.downloadPath.path())")
        return .init(
            downloadPath: Self.downloadPath,
            torrentsPath: Self.torrentPath,
            fastResumePath: Self.fastResumePath,
            configuration: TorrentSession.Configuration.fromPreferences(with: []),
            storages: PreferencesStorage.shared.storageScopes
        )
    }()

    private let disposeBag = DisposeBag()
    private var eventsTask: Task<Void, Never>?

    @Injected private var network: NetworkMonitoringService
    @Injected private var preferences: PreferencesStorage
    @Injected private var trackersListService: TrackersListService
}

extension TorrentService {
    var storages: [UUID: TorrentSession.Storage] {
        get { session.storages }
        set { session.storages = newValue }
    }

    func checkTorrentExists(with hash: TorrentSession.Hashes) -> Bool {
        modernHandles[hash] != nil
    }

    func modernHandle(for hash: TorrentSession.Hashes) -> TorrentSession.Handle? {
        modernHandles[hash]
    }

    func modernHandle(forHex hash: String) -> TorrentSession.Handle? {
        modernHandles.values.first(where: { $0.infoHashes.best.hex == hash })
    }

    var isBackgroundNeeded: Bool {
        modernHandles.values.contains { handle in
            handle.currentSnapshot?.needBackground == true
        }
    }

    @discardableResult
    func addTorrent(_ source: TorrentSession.Source, at storage: UUID? = nil) -> Bool {
        guard !checkTorrentExists(with: source.infoHashes) else { return false }

        _ = session.addTorrent(source, to: storage ?? preferences.defaultStorage)
        return true
    }

    func removeTorrent(by infoHashes: TorrentSession.Hashes, deleteFiles: Bool) {
        guard let handle = modernHandles[infoHashes]
        else { return }

        handle.deleteMetadata()
        Task { [session] in
            await session.removeTorrent(infoHashes, deleteFiles: deleteFiles)
        }
    }

    func updateSettings(_ settings: TorrentSession.Configuration) {
        session.configuration = settings
    }

    func refreshStorage(_ storage: TorrentSession.Storage) -> Bool {
        var storage = storage
        guard storage.resolveSequrityScopes() else { return false }

        preferences.storageScopes[storage.uuid] = storage

        let handles = modernHandles.values.filter { $0.currentSnapshot?.storageUUID == storage.uuid }
        handles.forEach { handle in
            Task { await handle.reload() }
        }
        return true
    }
}

private extension TorrentService {
    func setup() {
        resolveStorageScopes()

        session.pause()
        Task { [weak self] in
            guard let self else { return }
            let handles = await session.modernHandles()
            await MainActor.run {
                self.modernHandles = Dictionary(uniqueKeysWithValues: handles.map { ($0.infoHashes, $0) })
            }
        }
        session.resume()

        eventsTask = Task { [weak self] in
            guard let self else { return }

            for await event in session.handleEvents() {
                await self.handle(event)
            }
        }

        disposeBag.bind {
            Publishers.combineLatest(
                preferences.settingsUpdatePublisher,
                network.$availableInterfaces
            ) { _, interfaces in
                interfaces
            }
            .sink { [unowned self] interfaces in
                DispatchQueue.main.async { [self] in
                    session.configuration = TorrentSession.Configuration.fromPreferences(with: interfaces)
                }
            }

            preferences.$storageScopes.sink { [unowned self] storages in
                session.storages = storages
            }
        }
    }

    @MainActor
    func handle(_ event: TorrentSession.HandleEvent) async {
        switch event {
        case let .torrentAdded(handle):
            await handleTorrentAdded(handle)
        case let .torrentRemoved(hashes):
            handleTorrentRemoved(hashes)
        case let .torrentUpdated(handle):
            handleTorrentUpdated(handle)
        case .error:
            break
        }
    }

    @MainActor
    func handleTorrentAdded(_ handle: TorrentSession.Handle) async {
        _ = await handle.snapshot()
        modernHandles[handle.infoHashes] = handle

        if preferences.isTrackersAutoaddingEnabled {
            trackersListService.addAllTrackers(to: handle)
        }
    }

    @MainActor
    func handleTorrentRemoved(_ hashes: TorrentSession.Hashes) {
        guard let handle = modernHandles[hashes] else {
            return
        }

        if let oldSnapshot = handle.currentSnapshot {
            updateNotifier.send(.init(oldSnapshot: oldSnapshot, handle: nil))
        }

        handle.__removePublisher.send(handle)
        handle.finishUpdatePublishers()
        handle.updateCachedSnapshot(nil)
        modernHandles[hashes] = nil
    }

    @MainActor
    func handleTorrentUpdated(_ handle: TorrentSession.Handle) {
        if modernHandles[handle.infoHashes] !== handle {
            modernHandles[handle.infoHashes] = handle
        }

        handle.__unthrottledUpdatePublisher.send()
    }

    func resolveStorageScopes() {
        for key in preferences.storageScopes.keys {
            guard var scope = preferences.storageScopes[key] else { continue }
            scope.resolveSequrityScopes()
            preferences.storageScopes[key] = scope

            if !scope.allowed, preferences.defaultStorage == scope.uuid {
                preferences.defaultStorage = nil
            }
        }
    }
}

private extension TorrentService {
    func configureOpenSSLCerts() {
        guard let caPath = Bundle.main.path(forResource: "cacert", ofType: "pem") else {
            assertionFailure("cacert.pem not found in bundle")
            return
        }

        setenv("SSL_CERT_FILE", caPath, 1)
    }
}
