//
//  TorrentHandle+Extension.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 31/10/2023.
//

import Combine
import Foundation
import LibTorrent

private final class TorrentSessionHandlePublisherState: @unchecked Sendable {
    let unthrottledUpdatePublisher = PassthroughSubject<Void, Never>()
    let updatePublisher = PassthroughSubject<TorrentService.TorrentUpdateModel, Never>()
    let removePublisher = PassthroughSubject<TorrentSession.Handle, Never>()

    private var cancellables = Set<AnyCancellable>()

    init(handle: TorrentSession.Handle) {
        unthrottledUpdatePublisher
            .throttle(for: .seconds(0.1), scheduler: DispatchQueue.main, latest: true)
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .sink { [weak self, weak handle] in
                guard let self, let handle else { return }

                Task { [weak self, weak handle] in
                    guard let self, let handle else { return }

                    _ = handle.metadata // Trigger metadata generation if needed.
                    let oldSnapshot = handle.currentSnapshot
                    guard let snapshot = await handle.snapshot() else { return }
                    let updateModel = TorrentService.TorrentUpdateModel(
                        oldSnapshot: oldSnapshot ?? snapshot,
                        handle: handle
                    )

                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }
                        TorrentService.shared.updateNotifier.send(updateModel)
                        self.updatePublisher.send(updateModel)
                    }
                }
            }
            .store(in: &cancellables)
    }

    func finish(for handle: TorrentSession.Handle) {
        removePublisher.send(handle)
        unthrottledUpdatePublisher.send(completion: .finished)
        updatePublisher.send(completion: .finished)
        removePublisher.send(completion: .finished)
        cancellables.removeAll()
    }
}

private enum TorrentSessionHandlePublisherRegistry {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var states: [ObjectIdentifier: TorrentSessionHandlePublisherState] = [:]

    static func state(for handle: TorrentSession.Handle) -> TorrentSessionHandlePublisherState {
        let key = ObjectIdentifier(handle)

        lock.lock()
        defer { lock.unlock() }

        if let state = states[key] {
            return state
        }

        let state = TorrentSessionHandlePublisherState(handle: handle)
        states[key] = state
        return state
    }

    static func finish(for handle: TorrentSession.Handle) {
        let key = ObjectIdentifier(handle)

        lock.lock()
        let state = states.removeValue(forKey: key)
        lock.unlock()

        state?.finish(for: handle)
    }
}

extension TorrentHandle.Snapshot {
    var friendlyState: TorrentSession.Handle.State {
        TorrentSession.Handle.Snapshot(self).friendlyState
    }

    var canResume: Bool {
        TorrentSession.Handle.Snapshot(self).canResume
    }

    var canPause: Bool {
        TorrentSession.Handle.Snapshot(self).canPause
    }
}

extension TorrentSession.Handle {
    struct Metadata: Codable {
        var dateAdded: Date = .init()
    }

    var __unthrottledUpdatePublisher: PassthroughSubject<Void, Never> {
        TorrentSessionHandlePublisherRegistry.state(for: self).unthrottledUpdatePublisher
    }

    var __updatePublisher: PassthroughSubject<TorrentService.TorrentUpdateModel, Never> {
        TorrentSessionHandlePublisherRegistry.state(for: self).updatePublisher
    }

    var __removePublisher: PassthroughSubject<TorrentSession.Handle, Never> {
        TorrentSessionHandlePublisherRegistry.state(for: self).removePublisher
    }

    /// Does not contain the updated snapshot yet, it triggers the throttled refresh pipeline.
    var unthrottledUpdatePublisher: AnyPublisher<Void, Never> {
        __unthrottledUpdatePublisher.eraseToAnyPublisher()
    }

    /// Contains the old snapshot in `TorrentUpdateModel` and the updated snapshot on the handle itself.
    var updatePublisher: AnyPublisher<TorrentService.TorrentUpdateModel, Never> {
        __updatePublisher.eraseToAnyPublisher()
    }

    var removePublisher: AnyPublisher<TorrentSession.Handle, Never> {
        __removePublisher.eraseToAnyPublisher()
    }

    func finishUpdatePublishers() {
        TorrentSessionHandlePublisherRegistry.finish(for: self)
    }

    var storage: TorrentSession.Storage? {
        guard let storageUUID = currentSnapshot?.storageUUID else { return nil }
        return TorrentService.shared.storages[storageUUID]
    }

    var metadata: Metadata {
        let hash = infoHashes.best.hex
        let url = TorrentService.metadataPath.appendingPathComponent("\(hash).tmeta", isDirectory: false)
        if FileManager.default.fileExists(atPath: url.path()),
           let data = try? Data(contentsOf: url),
           let meta = try? JSONDecoder().decode(Metadata.self, from: data)
        {
            return meta
        }

        let meta = Metadata()
        if let data = try? JSONEncoder().encode(meta) {
            try? data.write(to: url)
        }
        return meta
    }

    func deleteMetadata() {
        let hash = infoHashes.best.hex
        let url = TorrentService.metadataPath.appendingPathComponent("\(hash).tmeta", isDirectory: false)
        try? FileManager.default.removeItem(at: url)
    }
}

extension TorrentSession.Handle.Snapshot {
    var friendlyState: TorrentSession.Handle.State {
        if isStorageMissing {
            return .storageError
        }

        switch state {
        case .downloading:
            if isPaused { return .paused }
            else { return .downloading }
        case .finished:
            if isPaused { return .finished }
            else { return .seeding }
        case .seeding:
            if isPaused { return .finished }
            else { return .seeding }
        default:
            return state
        }
    }

    var canResume: Bool {
        isPaused && friendlyState != .storageError
    }

    var canPause: Bool {
        !isPaused
    }
}

extension TorrentSession.Handle.State {
    var name: String {
        switch self {
        case .checkingFiles:
            return String(localized: "torrent.state.checkingFiles")
        case .downloadingMetadata:
            return String(localized: "torrent.state.fetchingMetadata")
        case .downloading:
            return String(localized: "torrent.state.downloading")
        case .finished:
            return String(localized: "torrent.state.done")
        case .seeding:
            return String(localized: "torrent.state.seeding")
        case .checkingResumeData:
            return String(localized: "torrent.state.resuming")
        case .paused:
            return String(localized: "torrent.state.paused")
        case .storageError:
            return String(localized: "torrent.state.storageError")
        }
    }
}

// MARK: - Storage
extension TorrentHandle {
    var storage: TorrentSession.Storage? {
        guard let storageUUID else { return nil }
        return TorrentService.shared.storages[storageUUID]
    }
}

// MARK: - Metadata
extension TorrentHandle {
    struct Metadata: Codable {
        var dateAdded: Date = .init()
    }

    var metadata: Metadata {
        if let _metadata { return _metadata }

        let hash = snapshot.infoHashes.best.hex
        let url = TorrentService.metadataPath.appendingPathComponent("\(hash).tmeta", isDirectory: false)
        if FileManager.default.fileExists(atPath: url.path()),
           let data = try? Data(contentsOf: url),
           let meta = try? JSONDecoder().decode(Metadata.self, from: data)
        {
            _metadata = meta
            return meta
        }

        let meta = Metadata()
        if let data = try? JSONEncoder().encode(meta) {
            try? data.write(to: url)
        }

        _metadata = meta
        return meta
    }

    func deleteMetadata() {
        let hash = snapshot.infoHashes.best.hex
        let url = TorrentService.metadataPath.appendingPathComponent("\(hash).tmeta", isDirectory: false)
        try? FileManager.default.removeItem(at: url)
    }
}

// MARK: - Metadata cache
private extension TorrentHandle {
    private enum MetaKeys {
        nonisolated(unsafe) static var metadataKey: Void?
    }

    var _metadata: Metadata? {
        get { objc_getAssociatedObject(self, &MetaKeys.metadataKey) as? Metadata }
        set { objc_setAssociatedObject(self, &MetaKeys.metadataKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
}
