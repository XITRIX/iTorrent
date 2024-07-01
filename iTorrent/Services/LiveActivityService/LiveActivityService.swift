//
//  LiveActivityService.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 06.04.2024.
//

#if canImport(ActivityKit)
import ActivityKit
import Combine
import LibTorrent
import MvvmFoundation
import UIKit
#endif

actor LiveActivityService {
    init() {
        disposeBag.bind {
#if canImport(ActivityKit)
            TorrentService.shared.updateNotifier
                .sink { [unowned self] updateModel in
                    Task { await updateLiveActivity(with: updateModel.handle.snapshot) }
                }
#endif
        }
    }

    private let disposeBag = DisposeBag()
    @Injected private var torrentService: TorrentService
}

#if canImport(ActivityKit)
private extension LiveActivityService {
    func updateLiveActivity(with snapshot: TorrentHandle.Snapshot) async {
        if #available(iOS 16.1, *) {
            guard ActivityAuthorizationInfo().areActivitiesEnabled
            else { return }

            for activity in Activity<ProgressWidgetAttributes>.activities {
                if activity.attributes.name == snapshot.name {
                    if snapshot.friendlyState.shouldShowLiveActivity {
                        if #available(iOS 16.2, *) {
                            await activity.update(.init(state: snapshot.toLiveActivityState, staleDate: .now + 10))
                        } else {
                            await activity.update(using: snapshot.toLiveActivityState)
                        }
                        return
                    } else {
                        await activity.end(dismissalPolicy: .immediate)
                        return
                    }
                }
            }

            if snapshot.friendlyState.shouldShowLiveActivity {
                showLiveActivity(with: snapshot)
            }
        }
    }

    func showLiveActivity(with snapshot: TorrentHandle.Snapshot) {
        if #available(iOS 16.1, *) {
            let attributes = ProgressWidgetAttributes(name: snapshot.name, hash: snapshot.infoHashes.best.hex)

            do {
                _ = try Activity<ProgressWidgetAttributes>.request(attributes: attributes, contentState: snapshot.toLiveActivityState, pushType: .none)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

private extension TorrentHandle.Snapshot {
    var toLiveActivityState: ProgressWidgetAttributes.ContentState {
        .init(state: friendlyState.toState,
              progress: progress,
              downSpeed: downloadRate,
              upSpeed: uploadRate,
              timeRemainig: timeRemains,
              timeStamp: Date())
    }
}

private extension TorrentHandle.State {
    var toState: ProgressWidgetAttributes.State {
        switch self {
        case .checkingFiles:
            return .checkingFiles
        case .downloadingMetadata:
            return .downloadingMetadata
        case .downloading:
            return .downloading
        case .finished:
            return .finished
        case .seeding:
            return .seeding
        case .checkingResumeData:
            return .checkingResumeData
        case .paused:
            return .paused
        case .storageError:
            return .storageError
        @unknown default:
            fatalError("\(ProgressWidgetAttributes.State.self) has no such case \(self)")
        }
    }

    var shouldShowLiveActivity: Bool {
        let notShow: [Self] = [.finished, .paused, .storageError]
        return !notShow.contains(self)
    }
}
#endif
