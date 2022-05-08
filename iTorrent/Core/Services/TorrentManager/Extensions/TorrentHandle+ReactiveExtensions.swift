//
//  TorrentHandleReactiveExtensions.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 25.04.2022.
//

import Bond
import Foundation
import ReactiveKit
import TorrentKit

extension TorrentHandle {
    fileprivate enum AssociatedKeys {
        static var InitObserver = "AssociatedKeyInitObserver"
        static var UpdateObserver = "AssociatedKeyUpdateObserver"
        static var RemovedObserver = "AssociatedKeyRemovedObserver"
    }

    var rx: Reactive<TorrentHandle> {
        reactive
    }
}

extension TorrentHandle: BindingExecutionContextProvider {
    public var bindingExecutionContext: ExecutionContext { return .immediateOnMain }
}

extension ReactiveExtensions where Base == TorrentHandle {
    func update() {
//        objc_sync_enter(self)
//        defer { objc_sync_exit(self) }
        
        updateObserver.receive(base)
    }

    var initObserver: SafeReplayOneSubject<TorrentHandle> {
        guard let subject = objc_getAssociatedObject(base, &Base.AssociatedKeys.InitObserver) as? SafeReplayOneSubject<TorrentHandle> else {
            let sub = SafeReplayOneSubject<TorrentHandle>()
            sub.receive(base)
            objc_setAssociatedObject(base, &Base.AssociatedKeys.InitObserver, sub, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            return sub
        }
        return subject
    }

    var updateObserver: SafeReplayOneSubject<TorrentHandle> {
        guard let subject = objc_getAssociatedObject(base, &Base.AssociatedKeys.UpdateObserver) as? SafeReplayOneSubject<TorrentHandle> else {
            let sub = SafeReplayOneSubject<TorrentHandle>()
            sub.receive(base)
            objc_setAssociatedObject(base, &Base.AssociatedKeys.UpdateObserver, sub, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            return sub
        }
        return subject
    }

    var removedObserver: SafeReplayOneSubject<Bool> {
        guard let subject = objc_getAssociatedObject(base, &Base.AssociatedKeys.RemovedObserver) as? SafeReplayOneSubject<Bool> else {
            let sub = SafeReplayOneSubject<Bool>()
            sub.receive(false)
            objc_setAssociatedObject(base, &Base.AssociatedKeys.RemovedObserver, sub, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            return sub
        }
        return subject
    }
    
    var name: Signal<String, Never> {
        updateObserver.map { $0.snapshot.name }
    }

    var progress: Signal<Float, Never> {
        updateObserver.map { Float($0.snapshot.progress) }
    }

    var progressTotal: Signal<Float, Never> {
        updateObserver.map {
            guard $0.snapshot.totalDone > 0 else { return 0 }
            return Float($0.snapshot.totalDone) / Float($0.snapshot.total)
        }
    }

    var displayState: Signal<TorrentHandle.State, Never> {
        updateObserver.map { $0.displayState }
    }

    var downloadRate: Signal<UInt, Never> {
        updateObserver.map { $0.snapshot.downloadRate }
    }

    var uploadRate: Signal<UInt, Never> {
        updateObserver.map { $0.snapshot.uploadRate }
    }

    var isSequential: DynamicSubject<Bool> {
        return dynamicSubject(
            signal: initObserver.eraseType(),
            get: { $0.snapshot.isSequential },
            set: { $0.setSequentialDownload($1) }
        )
    }

    var infoHash: Signal<String, Never> {
        updateObserver.map { $0.snapshot.infoHash.hex }
    }

    var creator: Signal<String?, Never> {
        updateObserver.map { $0.snapshot.creator }
    }

    var creationDate: Signal<Date?, Never> {
        updateObserver.map { $0.snapshot.creationDate }
    }

    var totalDownload: Signal<UInt, Never> {
        updateObserver.map { $0.snapshot.totalDownload }
    }

    var totalUpload: Signal<UInt, Never> {
        updateObserver.map { $0.snapshot.totalUpload }
    }

    var total: Signal<UInt, Never> {
        updateObserver.map { $0.snapshot.total }
    }

    var totalWanted: Signal<UInt, Never> {
        updateObserver.map { $0.snapshot.totalWanted }
    }

    var totalDone: Signal<UInt, Never> {
        updateObserver.map { $0.snapshot.totalDone }
    }

    var numberOfSeeds: Signal<UInt, Never> {
        updateObserver.map { $0.snapshot.numberOfSeeds }
    }

    var numberOfPeers: Signal<UInt, Never> {
        updateObserver.map { $0.snapshot.numberOfPeers }
    }

    var numberOfLeechers: Signal<UInt, Never> {
        updateObserver.map { $0.snapshot.numberOfLeechers }
    }

    var numberOfTotalSeeds: Signal<UInt, Never> {
        updateObserver.map { $0.snapshot.numberOfTotalSeeds }
    }

    var numberOfTotalPeers: Signal<UInt, Never> {
        updateObserver.map { $0.snapshot.numberOfTotalPeers }
    }

    var numberOfTotalLeechers: Signal<UInt, Never> {
        updateObserver.map { $0.snapshot.numberOfTotalLeechers }
    }

    var canResume: Signal<Bool, Never> {
        updateObserver.map { $0.canResume }
    }

    var canPause: Signal<Bool, Never> {
        updateObserver.map { $0.canPause }
    }

    var pieces: Signal<[Bool], Never> {
        updateObserver.map { $0.snapshot.pieces.map { $0.boolValue } }
    }
}
