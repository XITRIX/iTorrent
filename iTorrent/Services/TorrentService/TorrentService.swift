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
        let oldSnapshot: TorrentHandle.Snapshot
        let handle: TorrentHandle?
    }
}

class TorrentService: @unchecked Sendable {
    @Published var torrents: [TorrentHashes: TorrentHandle] = [:]
    var updateNotifier = PassthroughSubject<TorrentUpdateModel, Never>()

    static let shared = TorrentService()
    static var version: String { Version.libtorrentVersion }

    init() { setup() }

    static let downloadPath: URL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    static let torrentPath: URL = downloadPath.appending(path: "config")
    static let fastResumePath: URL = downloadPath.appending(path: "config")
    static let metadataPath: URL = downloadPath.appending(path: "config")

    private lazy var session: Session = {
        configureOpenSSLCerts()
        var settings = Session.Settings()
        print("Working directory: \(Self.downloadPath.path())")
        return .init(Self.downloadPath.path(), torrentsPath: Self.torrentPath.path(), fastResumePath: Self.fastResumePath.path(), settings: .fromPreferences(with: []), storages: PreferencesStorage.shared.storageScopes)
    }()

    private let disposeBag = DisposeBag()

    @Injected private var network: NetworkMonitoringService
    @Injected private var preferences: PreferencesStorage
    @Injected private var trackersListService: TrackersListService
}

extension TorrentService {
    var storages: [UUID: StorageModel] {
        get { session.storages }
        set { session.storages = newValue }
    }

    func checkTorrentExists(with hash: TorrentHashes) -> Bool {
        session.torrentsMap[hash] != nil
    }

    @discardableResult
    func addTorrent(by file: Downloadable, at storage: UUID? = nil) -> Bool {
        guard session.torrentsMap[file.infoHashes] == nil
        else { return false }

        session.addTorrent(file, to: storage ?? preferences.defaultStorage)
        return true
    }

    func removeTorrent(by infoHashes: TorrentHashes, deleteFiles: Bool) {
        guard let handle = session.torrentsMap[infoHashes]
        else { return }

        let oldSnapshot = handle.snapshot
        handle.deleteMetadata()
        session.removeTorrent(handle, deleteFiles: deleteFiles)
        let updateModel = TorrentService.TorrentUpdateModel(oldSnapshot: oldSnapshot, handle: nil)
        updateNotifier.send(updateModel)
    }

    func updateSettings(_ settings: Session.Settings) {
        session.settings = settings
    }

    func refreshStorage(_ storage: StorageModel) -> Bool {
        guard storage.resolveSequrityScopes() else { return false }

        let handles = torrents.values.filter { $0.storageUUID == storage.uuid }
        handles.forEach { $0.reload() }
        return true
    }
}

// MARK: - SessionDelegate
extension TorrentService: SessionDelegate {
    func torrentManager(_ manager: Session, didAddTorrent torrent: TorrentHandle) {
        torrent.prepareToAdd(into: self)
        torrents[torrent.snapshot.infoHashes] = torrent

        // Add trackers from torrent list service if needed
        if preferences.isTrackersAutoaddingEnabled {
            trackersListService.addAllTrackers(to: torrent)
        }
    }

    func torrentManager(_ manager: Session, didRemoveTorrentWithHash hashesData: TorrentHashes) {
        guard let torrent = torrents[hashesData]
        else { return }

        torrent.removePublisher.send(torrent)
        torrents[hashesData] = nil
    }

    func torrentManager(_ manager: Session, didReceiveUpdateForTorrent torrent: TorrentHandle) {
        torrent.__unthrottledUpdatePublisher.send()
    }

    func torrentManager(_ manager: Session, didErrorOccur error: Error) { /* Not implemented yet */ }
}

private extension TorrentService {
    func setup() {
        // Resolve storage scopes, so Core will be able to restore states
        resolveStorageScopes()

        // Pause the core, so it will not deadlock app on making first snapshots
        session.pause()
        torrents = session.torrentsMap.mapValues { torrent in
            torrent.prepareToAdd(into: self)
            return torrent
        }
        // After initialization is done we could resume core
        session.resume()
        session.add(self)

        disposeBag.bind {
            Publishers.combineLatest(
                preferences.settingsUpdatePublisher,
                network.$availableInterfaces
            ) { _, interfaces in
                interfaces
            }
            .sink { [unowned self] interfaces in
                DispatchQueue.main.async { [self] in // Need delay to complete settings apply
                    session.settings = Session.Settings.fromPreferences(with: interfaces)
                }
            }

            preferences.$storageScopes.sink { [unowned self] storages in
                session.storages = storages
            }
        }
    }

    func resolveStorageScopes() {
        preferences.storageScopes.values.forEach { scope in
            scope.resolveSequrityScopes()

            // If storage is not allowed and it used as default, reset default
            if !scope.allowed, preferences.defaultStorage == scope.uuid {
                preferences.defaultStorage = nil
            }
        }
    }
}

private extension TorrentHandle {
    func prepareToAdd(into torrentServide: TorrentService) {
        updateSnapshot()

        disposeBag.bind {
            __unthrottledUpdatePublisher
                .throttle(for: .seconds(0.1), scheduler: .main, latest: true)
                .receive(on: DispatchQueue.global(qos: .userInitiated))
                .sink { [weak self, weak torrentServide] in
                    guard let self, let torrentServide else { return }

                    _ = metadata // trigger to generate
                    let oldSnapshot = snapshot
                    updateSnapshot()
                    let updateModel = TorrentService.TorrentUpdateModel(oldSnapshot: oldSnapshot, handle: self)

                    Task { @MainActor in
                        torrentServide.updateNotifier.send(updateModel)
                        self.__updatePublisher.send(updateModel)
                    }
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

        // This is the important line:
        setenv("SSL_CERT_FILE", caPath, 1)
    }
}
