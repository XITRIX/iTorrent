//
//  LiveActivityService.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 06.04.2024.
//

#if canImport(ActivityKit)
import ActivityKit
#endif

import Combine
import LibTorrent
import MvvmFoundation
import UIKit

actor LiveActivityService {
    init() {
        disposeBag.bind {
#if canImport(ActivityKit)
            TorrentService.shared.updateNotifier
                .sink { [unowned self] updateModel in
                    Task { await updateLiveActivity(with: updateModel) }
                }
#endif
        }
    }

    private static let throttleDuration: Int = 5
    private var throttleMap: [String: Date] = [:]
    private let disposeBag = DisposeBag()
    @Injected private var torrentService: TorrentService
}

extension LiveActivityService {
    static func endAllLiveActivities() {
#if canImport(ActivityKit)
        if #available(iOS 16.2, *) {
            let semaphore = DispatchSemaphore(value: 0)
            Task.detached {
                print("Terminating live activities...")
                for activity in Activity<ProgressWidgetAttributes>.activities {
                    await activity.end(nil, dismissalPolicy: .immediate)
                }
                semaphore.signal()
            }
            semaphore.wait()
        }
#endif
    }
}

#if canImport(ActivityKit)
private extension LiveActivityService {
    func updateLiveActivity(with updateModel: TorrentService.TorrentUpdateModel) async {
        if #available(iOS 16.1, *) {
            guard ActivityAuthorizationInfo().areActivitiesEnabled
            else { return }

            for activity in Activity<ProgressWidgetAttributes>.activities {
                if activity.attributes.hash == updateModel.oldSnapshot.infoHashes.best.hex {
                    if let snapshot = updateModel.handle?.snapshot,
                        snapshot.friendlyState.shouldShowLiveActivity
                    {
                        await update(activity, with: snapshot.toLiveActivityState)
                        return
                    } else {
                        await end(activity)
                        return
                    }
                }
            }

            if let snapshot = updateModel.handle?.snapshot,
               snapshot.friendlyState.shouldShowLiveActivity
            {
                showLiveActivity(with: snapshot)
            }
        }
    }

    @available(iOS 16.1, *)
    func update(_ activity: Activity<ProgressWidgetAttributes>, with state: ProgressWidgetAttributes.ContentState) async {
//        if #available(iOS 16.2, *) {
//            guard activity.content.state != state
//            else { return }
//        } else {
//            guard activity.contentState != state
//            else { return }
//        }

        if let date = throttleMap[activity.attributes.hash],
            Int(Date.now.timeIntervalSince(date)) <= Self.throttleDuration
        { return }

        if #available(iOS 16.2, *) {
            await activity.update(.init(state: state, staleDate: .now + 10, relevanceScore: state.state.relevanceScore))
        } else {
            await activity.update(using: state)
        }

        throttleMap[activity.attributes.hash] = .now
    }

    @available(iOS 16.1, *)
    func end(_ activity: Activity<ProgressWidgetAttributes>) async {
        await activity.end(dismissalPolicy: .immediate)
        throttleMap[activity.attributes.hash] = nil
    }

    func showLiveActivity(with snapshot: TorrentHandle.Snapshot) {
        if #available(iOS 16.1, *) {
            let attributes = ProgressWidgetAttributes(hash: snapshot.infoHashes.best.hex)

            do {
                _ = try Activity<ProgressWidgetAttributes>.request(attributes: attributes, contentState: snapshot.toLiveActivityState, pushType: .none)
                throttleMap[attributes.hash] = .now
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

private extension ProgressWidgetAttributes.State {
    var relevanceScore: Double {
        switch self {
        case .checkingFiles:
            2
        case .downloadingMetadata:
            3
        case .downloading:
            5
        case .finished:
            0
        case .seeding:
            4
        case .checkingResumeData:
            1
        case .paused:
            0
        case .storageError:
            0
        }
    }
}

private extension TorrentHandle.Snapshot {
    var toLiveActivityState: ProgressWidgetAttributes.ContentState {
        let color = PreferencesStorage.shared.tintColor
        let data = try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: true)

        return .init(name: name,
              state: friendlyState.toState,
              progress: progress,
              downSpeed: downloadRate,
              upSpeed: uploadRate,
              timeRemainig: timeRemains,
              timeStamp: Date(), 
              color: data)
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
