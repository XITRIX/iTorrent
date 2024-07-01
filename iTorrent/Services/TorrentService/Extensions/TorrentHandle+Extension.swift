//
//  TorrentHandle+Extension.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 31/10/2023.
//

import Combine
import LibTorrent
import MvvmFoundation

private var TorrentHandleUnthrottledUpdatePublisherKey: UInt8 = 0
private var TorrentHandleUpdatePublisherKey: UInt8 = 0
private var TorrentHandleRemovePublisherKey: UInt8 = 0
private var TorrentHandleDisposeBagKey: UInt8 = 0

extension TorrentHandle {
    var disposeBag: DisposeBag {
        guard let obj = objc_getAssociatedObject(self, &TorrentHandleDisposeBagKey) as? DisposeBag
        else {
            objc_setAssociatedObject(self, &TorrentHandleDisposeBagKey, DisposeBag(), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            return objc_getAssociatedObject(self, &TorrentHandleDisposeBagKey) as! DisposeBag
        }
        return obj
    }

    var __unthrottledUpdatePublisher: PassthroughSubject<Void, Never> {
        guard let obj = objc_getAssociatedObject(self, &TorrentHandleUnthrottledUpdatePublisherKey) as? PassthroughSubject<Void, Never>
        else {
            objc_setAssociatedObject(self, &TorrentHandleUnthrottledUpdatePublisherKey, PassthroughSubject<Void, Never>(), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            return objc_getAssociatedObject(self, &TorrentHandleUnthrottledUpdatePublisherKey) as! PassthroughSubject<Void, Never>
        }
        return obj
    }

    var __updatePublisher: PassthroughSubject<TorrentService.TorrentUpdateModel, Never> {
        guard let obj = objc_getAssociatedObject(self, &TorrentHandleUpdatePublisherKey) as? PassthroughSubject<TorrentService.TorrentUpdateModel, Never>
        else {
            objc_setAssociatedObject(self, &TorrentHandleUpdatePublisherKey, PassthroughSubject<TorrentService.TorrentUpdateModel, Never>(), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            return objc_getAssociatedObject(self, &TorrentHandleUpdatePublisherKey) as! PassthroughSubject<TorrentService.TorrentUpdateModel, Never>
        }
        return obj
    }

    /// Does not contain updated Snapshot yet, it creates before updatePublisher will be fired
    ///
    /// Better not use this one, prefer to use `updatePublisher`
    var unthrottledUpdatePublisher: AnyPublisher<Void, Never> {
        __unthrottledUpdatePublisher.eraseToAnyPublisher()
    }

    /// Contains old Snapshot in `TorrentUpdateModel` and updated Snapshot inside of `TorrentHandle` it self
    var updatePublisher: AnyPublisher<TorrentService.TorrentUpdateModel, Never> {
        __updatePublisher.eraseToAnyPublisher()
    }

    var removePublisher: PassthroughSubject<TorrentHandle, Never> {
        guard let obj = objc_getAssociatedObject(self, &TorrentHandleRemovePublisherKey) as? PassthroughSubject<TorrentHandle, Never>
        else {
            objc_setAssociatedObject(self, &TorrentHandleRemovePublisherKey, PassthroughSubject<TorrentHandle, Never>(), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            return objc_getAssociatedObject(self, &TorrentHandleRemovePublisherKey) as! PassthroughSubject<TorrentHandle, Never>
        }
        return obj
    }
}

extension TorrentHandle.Snapshot {
    var friendlyState: TorrentHandle.State {
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

extension TorrentHandle.State {
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
        @unknown default:
            assertionFailure("Unregistered \(Self.self) enum value is not allowed: \(self)")
            return ""
        }
    }
}

// MARK: - Storage
extension TorrentHandle.Snapshot {
    var storage: StorageModel? {
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
    private enum Keys {
        static var metadataKey: Void?
    }

    var _metadata: Metadata? {
        get { objc_getAssociatedObject(self, &Keys.metadataKey) as? Metadata }
        set { objc_setAssociatedObject(self, &Keys.metadataKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
}
