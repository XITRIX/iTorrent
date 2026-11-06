//
//  LiveActivityService.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 06.04.2024.
//

#if canImport(ActivityKit)
@preconcurrency import ActivityKit
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
                    // Acquire execution time before the publisher's next subscriber
                    // can stop the download's background service.
                    let needsDismissal = updateModel.handle.map {
                        !$0.snapshot.friendlyState.shouldShowLiveActivity
                    } ?? true
                    let backgroundTask = needsDismissal ? LiveActivityBackgroundTask() : nil
                    Task {
                        defer { backgroundTask?.end() }
                        await updateLiveActivity(with: updateModel)
                    }
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
    static func endPreviousLiveActivities() {
#if canImport(ActivityKit)
        if #available(iOS 16.1, *) {
            // Capture the previous process's activities before scene setup can
            // start new ones for the restored downloads.
            let activities = Activity<ProgressWidgetAttributes>.activities
            guard !activities.isEmpty else { return }
            let backgroundTask = LiveActivityBackgroundTask()
            Task.detached {
                defer { backgroundTask.end() }
                await dismiss(activities)
            }
        }
#endif
    }

    static func endAllLiveActivities() {
#if canImport(ActivityKit)
        if #available(iOS 16.1, *) {
            let activities = Activity<ProgressWidgetAttributes>.activities
            guard !activities.isEmpty else { return }
            let semaphore = DispatchSemaphore(value: 0)
            Task.detached(priority: .high) {
                await dismiss(activities)
                semaphore.signal()
            }
            // UIKit gives termination callbacks limited time. Never wait
            // indefinitely if ActivityKit cannot finish before the process exits.
            _ = semaphore.wait(timeout: .now() + 2)
        }
#endif
    }

#if canImport(ActivityKit)
    @available(iOS 16.1, *)
    private static func dismiss(_ activities: [Activity<ProgressWidgetAttributes>]) async {
        await withTaskGroup(of: Void.self) { group in
            for activity in activities {
                group.addTask {
                    if #available(iOS 16.2, *) {
                        await activity.end(nil, dismissalPolicy: .immediate)
                    } else {
                        await activity.end(using: nil, dismissalPolicy: .immediate)
                    }
                }
            }
        }
    }
#endif
}

#if canImport(ActivityKit)
private final class LiveActivityBackgroundTask: @unchecked Sendable {
    private let application: UIApplication = .shared
    private let lock = NSLock()
    private var identifier: UIBackgroundTaskIdentifier = .invalid
    private var hasEnded = false

    init() {
        let identifier = application.beginBackgroundTask(withName: "Live Activity dismissal") { [weak self] in
            self?.end()
        }

        lock.lock()
        // Expiration can arrive before beginBackgroundTask returns.
        if hasEnded {
            lock.unlock()
            if identifier != .invalid { application.endBackgroundTask(identifier) }
        } else {
            self.identifier = identifier
            lock.unlock()
        }
    }

    func end() {
        lock.lock()
        hasEnded = true
        let identifier = self.identifier
        self.identifier = .invalid
        lock.unlock()

        if identifier != .invalid { application.endBackgroundTask(identifier) }
    }
}

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
