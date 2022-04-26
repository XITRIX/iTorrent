//
//  TorrentHandleReactiveExtensions.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 25.04.2022.
//

import ReactiveKit
import Foundation
import TorrentKit
import Bond

extension TorrentHandle {
    fileprivate enum AssociatedKeys {
        static var UpdateObserver = "AssociatedKeyUpdateObserver"
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
        updateObserver.receive(base)
    }

    var initObserver: SafeReplayOneSubject<TorrentHandle> {
        guard let subject = objc_getAssociatedObject(base, &Base.AssociatedKeys.UpdateObserver) as? SafeReplayOneSubject<TorrentHandle> else {
            let sub = SafeReplayOneSubject<TorrentHandle>()
            sub.receive(base)
            objc_setAssociatedObject(base, &Base.AssociatedKeys.UpdateObserver, sub, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
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

    var name: Signal<String, Never> {
        updateObserver.map { $0.name }
    }

    var progress: Signal<Float, Never> {
        updateObserver.map { Float($0.progress) }
    }

    var progressTotal: Signal<Float, Never> {
        updateObserver.map {
            guard $0.totalDone > 0 else { return 0 }
            return Float($0.totalDone) / Float($0.total)

        }
    }

    var displayState: Signal<TorrentHandle.State, Never> {
        updateObserver.map { $0.displayState }
    }

    var downloadRate: Signal<UInt, Never> {
        updateObserver.map { $0.downloadRate }
    }

    var uploadRate: Signal<UInt, Never> {
        updateObserver.map { $0.uploadRate }
    }

    var isSequential: DynamicSubject<Bool> {
        return dynamicSubject(
            signal: initObserver.eraseType(),
            get: { $0.isSequential },
            set: { $0.setSequentialDownload($1) }
        )
    }

    var infoHash: Signal<String, Never> {
        updateObserver.map { $0.infoHash.hex }
    }

    var creator: Signal<String?, Never> {
        updateObserver.map { $0.creator }
    }

    var creationDate: Signal<Date?, Never> {
        updateObserver.map { $0.creationDate }
    }

    var totalDownload: Signal<UInt, Never> {
        updateObserver.map { $0.totalDownload }
    }

    var totalUpload: Signal<UInt, Never> {
        updateObserver.map { $0.totalUpload }
    }

    var total: Signal<UInt, Never> {
        updateObserver.map { $0.total }
    }

    var totalWanted: Signal<UInt, Never> {
        updateObserver.map { $0.totalWanted }
    }

    var totalDone: Signal<UInt, Never> {
        updateObserver.map { $0.totalDone }
    }

    var numberOfSeeds: Signal<UInt, Never> {
        updateObserver.map { $0.numberOfSeeds }
    }

    var numberOfPeers: Signal<UInt, Never> {
        updateObserver.map { $0.numberOfPeers }
    }

    var numberOfLeechers: Signal<UInt, Never> {
        updateObserver.map { $0.numberOfLeechers }
    }

    var numberOfTotalSeeds: Signal<UInt, Never> {
        updateObserver.map { $0.numberOfTotalSeeds }
    }

    var numberOfTotalPeers: Signal<UInt, Never> {
        updateObserver.map { $0.numberOfTotalPeers }
    }

    var numberOfTotalLeechers: Signal<UInt, Never> {
        updateObserver.map { $0.numberOfTotalLeechers }
    }

    var canResume: Signal<Bool, Never> {
        updateObserver.map { $0.canResume }
    }

    var canPause: Signal<Bool, Never> {
        updateObserver.map { $0.canPause }
    }

    var pieces: Signal<[Bool], Never> {
        updateObserver.map { $0.pieces.map { $0.boolValue } }
    }
}
