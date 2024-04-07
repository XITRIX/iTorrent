//
//  SceneDelegate+LiveActivity.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 06.04.2024.
//

#if canImport(ActivityKit)
import ActivityKit
import Combine
import LibTorrent
import UIKit
#endif

extension SceneDelegate {
    func bindLiveActivity() {
#if canImport(ActivityKit)
        disposeBag.bind {
            TorrentService.shared.updateNotifier
                .throttle(for: .seconds(0.25), scheduler: DispatchQueue.main, latest: true)
                .filter { _ in PreferencesStorage.shared.backgroundMode == .location }
                .sink { [unowned self] updateModel in
                    updateLiveActivity(with: updateModel)
                }
        }
#endif
    }
}

#if canImport(ActivityKit)
private extension SceneDelegate {
    func updateLiveActivity(with updateModel: TorrentService.TorrentUpdateModel) {
        if updateModel.oldSnapshot.state != updateModel.handle.snapshot.state,
           updateModel.handle.snapshot.friendlyState == .downloading
        {
            showLiveActivity(with: updateModel.handle.snapshot)
        } else {
            updateLiveActivity(with: updateModel.handle.snapshot)
        }
    }

    func showLiveActivity(with snapshot: TorrentHandle.Snapshot) {
        if #available(iOS 16.1, *) {
            guard ActivityAuthorizationInfo().areActivitiesEnabled
            else { return }

            let attributes = ProgressWidgetAttributes(name: snapshot.name, hash: snapshot.infoHashes.best.hex)

            DispatchQueue.main.async {
                do {
                    _ = try Activity<ProgressWidgetAttributes>.request(attributes: attributes, contentState: snapshot.toLiveActivityState, pushType: .none)
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }

    func updateLiveActivity(with snapshot: TorrentHandle.Snapshot) {
        if #available(iOS 16.1, *) {
            guard ActivityAuthorizationInfo().areActivitiesEnabled
            else { return }

            Task {
                for activity in Activity<ProgressWidgetAttributes>.activities {
                    if activity.attributes.name == snapshot.name {
                        if snapshot.friendlyState == .downloading {
                            await activity.update(using: snapshot.toLiveActivityState)
                            return
                        } else {
                            await activity.end(dismissalPolicy: .immediate)
                            return
                        }
                    }
                }

                if snapshot.friendlyState == .downloading {
                    showLiveActivity(with: snapshot)
                }
            }
        }
    }
}

private extension TorrentHandle.Snapshot {
    var toLiveActivityState: ProgressWidgetAttributes.ContentState {
        .init(progress: progress,
              downSpeed: downloadRate,
              upSpeed: uploadRate,
              timeRemainig: timeRemains,
              timeStamp: Date())
    }
}
#endif
