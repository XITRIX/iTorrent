//
//  ProgressWidgetLiveActivity.swift
//  ProgressWidget
//
//  Created by Даниил Виноградов on 06.04.2024.
//

#if canImport(ActivityKit)
import ActivityKit
import AppIntents
import MarqueeText
import SwiftUI
import WidgetKit

struct ProgressWidgetLiveActivity: Widget {
    static var userDefaults: UserDefaults { .itorrentGroup }

    static var tintColor: UIColor {
        guard let data = Self.userDefaults.data(forKey: "preferencesTintColor")
        else { return .tintColor }
        return (try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data)) ?? .tintColor
    }

    var body: some WidgetConfiguration {
        let config = ActivityConfiguration(for: ProgressWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here

            if #available(iOS 18, *) {
#if XCODE16
                ProgressWidgetLiveActivityWatchSupportContent(context: context)
                    .tint(Color(uiColor: ProgressWidgetLiveActivity.tintColor))
                    .padding()
#else
                ProgressWidgetLiveActivityContent(context: context)
                    .tint(Color(uiColor: Self.tintColor))
                    .padding()
#endif

            } else {
                ProgressWidgetLiveActivityContent(context: context)
                    .tint(Color(uiColor: Self.tintColor))
                    .padding()
            }
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    LeadingView(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.state == .seeding {
                        Image(systemName: "arrow.up.to.line")
                    } else {
                        Text(String("\(String(format: "%.2f", context.state.progress * 100))%")).padding(.top, 2)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack {
                        HStack {
                            Text(context.attributes.name).padding(.top, 2)
                            Spacer()
                            if context.state.state == .downloading {
                                Text(context.state.timeRemainig)
                            }

                            if #available(iOS 17.0, *),
                               context.state.state == .seeding
                            {
                                let intent = {
                                    let intent = PauseTorrentIntent()
                                    intent.torrentHash = context.attributes.hash
                                    return intent
                                }()
                                PauseButton(intent: intent)
                            }
                        }
                        ProgressView(value: context.state.progress)
                            .progressViewStyle(.linear)
                            .padding([.leading, .trailing], 8)
                    }
                    .tint(Color(uiColor: Self.tintColor))
                }
            } compactLeading: {
                LeadingView(context: context)
            } compactTrailing: {
                TrailingView(context: context)
            } minimal: {
                TrailingView(context: context)
            }
            .widgetURL(URL(string: "iTorrent:hash:\(context.attributes.hash)"))
            .keylineTint(Color(uiColor: Self.tintColor))
        }

        if #available(iOS 18.0, *) {
#if XCODE16
            return config.supplementalActivityFamilies([.small])
#else
            return config
#endif
        } else {
            return config
        }
    }
}

#if XCODE16
@available(iOS 18.0, *)
struct ProgressWidgetLiveActivityWatchSupportContent: View {
    @Environment(\.activityFamily) var activityFamily
    @State var context: ActivityViewContext<ProgressWidgetAttributes>

    var body: some View {
        if activityFamily == .medium {
            ProgressWidgetLiveActivityContent(context: context)
        } else {
            VStack(spacing: 8) {
                HStack {
                    MarqueeText(
                        text: context.attributes.name,
                        font: UIFont.preferredFont(forTextStyle: .caption1),
                        leftFade: 16,
                        rightFade: 16,
                        startDelay: 3)
                    Spacer()
                }
                HStack {
                    switch context.state.state {
                    case .checkingFiles:
                        Text(context.state.state.name)
                        Spacer()
                    case .downloadingMetadata:
                        Text(context.state.state.name)
                        Spacer()
                    case .downloading:
                        Text(String("\(context.state.downSpeed.bitrateToHumanReadable)/s ↓"))
                        Spacer()
                        Text(String("\(context.state.upSpeed.bitrateToHumanReadable)/s ↑"))
                    case .finished:
                        Text(context.state.state.name)
                        Spacer()
                    case .seeding:
                        Text(context.state.state.name)
                        Spacer()
                        Text(String("\(context.state.upSpeed.bitrateToHumanReadable)/s ↑"))
                    case .checkingResumeData:
                        Text(context.state.state.name)
                        Spacer()
                    case .paused:
                        Text(context.state.state.name)
                        Spacer()
                    case .storageError:
                        EmptyView()
                    }
                }
                .font(.caption2)
                .foregroundColor(.secondary)

                HStack {
                    ProgressView(value: context.state.progress)
                        .progressViewStyle(.linear)
                    Text(String("\(String(format: "%.2f", context.state.progress * 100))%"))
                        .font(.caption2)
                        .monospaced()
                }
            }
            .widgetURL(URL(string: "iTorrent:hash:\(context.attributes.hash)"))
        }
    }
}
#endif

struct ProgressWidgetLiveActivityContent: View {
    @State var context: ActivityViewContext<ProgressWidgetAttributes>

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(context.attributes.name)
                Spacer()

                if #available(iOS 17.0, *),
                   context.state.state == .seeding
                {
                    let intent = {
                        let intent = PauseTorrentIntent()
                        intent.torrentHash = context.attributes.hash
                        return intent
                    }()
                    PauseButton(intent: intent)
                }
            }
            HStack {
                switch context.state.state {
                case .checkingFiles:
                    Text(context.state.state.name)
                case .downloadingMetadata:
                    Text(context.state.state.name)
                case .downloading:
                    Text(String("\(context.state.downSpeed.bitrateToHumanReadable)/s ↓"))
                    Text(String(" | "))
                    Text(String("\(context.state.upSpeed.bitrateToHumanReadable)/s ↑"))
                case .finished:
                    Text(context.state.state.name)
                case .seeding:
                    Text(context.state.state.name)
                    Text(String(" | "))
                    Text(String("\(context.state.upSpeed.bitrateToHumanReadable)/s ↑"))
                case .checkingResumeData:
                    Text(context.state.state.name)
                case .paused:
                    Text(context.state.state.name)
                case .storageError:
                    EmptyView()
                }

                Spacer()
                Text(String("\(String(format: "%.2f", context.state.progress * 100))%"))
            }
            .font(.subheadline)
            .foregroundColor(.secondary)

            ProgressView(value: context.state.progress)
                .progressViewStyle(.linear)
        }
        .widgetURL(URL(string: "iTorrent:hash:\(context.attributes.hash)"))
    }
}

@available(iOS 17.0, *)
struct PauseButton: View {
    let intent: any LiveActivityIntent

    var body: some View {
        Button(intent: intent) {
            Image(systemName: "pause.fill")
        }
    }
}

struct LeadingView: View {
    @State var context: ActivityViewContext<ProgressWidgetAttributes>

    var body: some View {
        switch context.state.state {
        case .downloading:
            Text(String("\(context.state.downSpeed.bitrateToHumanReadable)/s"))
        case .checkingFiles:
            Image(systemName: "arrow.triangle.2.circlepath")
        case .downloadingMetadata:
            Image(systemName: "arrow.up.arrow.down")
        case .finished:
            EmptyView()
        case .seeding:
            Text(String("\(context.state.upSpeed.bitrateToHumanReadable)/s"))
        case .checkingResumeData:
            Image(systemName: "arrow.triangle.2.circlepath")
        case .paused:
            Image(systemName: "pause.fill")
        case .storageError:
            EmptyView()
        }
    }
}

struct TrailingView: View {
    @State var context: ActivityViewContext<ProgressWidgetAttributes>

    var body: some View {
        if context.state.state == .seeding {
            Image(systemName: "arrow.up.to.line")
        } else {
            ProgressView(value: context.state.progress)
                .progressViewStyle(.circular)
                .tint(Color(uiColor: ProgressWidgetLiveActivity.tintColor))
        }
    }
}

// #Preview("Progress",
//         as: .dynamicIsland(.compact),
//         using: ProgressWidgetAttributes(name: "Test torrent", hash: "")
// ) {
//    ProgressWidgetLiveActivity()
// } contentStates: {
//    ProgressWidgetAttributes.ContentState(progress: 0.2, downSpeed: 2000, upSpeed: 1000, timeRemainig: "Осталось САСАТБ", timeStamp: .now)
// }

// #Preview("Notification", as: .content, using: ProgressWidgetAttributes(name: "Test torrent", hash: "")) {
//    ProgressWidgetLiveActivity()
// } contentStates: {
//    ProgressWidgetAttributes.ContentState(progress: 0.2, downSpeed: 2000, upSpeed: 1000, timeRemainig: "Осталось САСАТБ", timeStamp: .now)
//    ProgressWidgetAttributes.ContentState(progress: 0.7, downSpeed: 12000000, upSpeed: 1000000, timeRemainig: "Осталось САСАТБ", timeStamp: .now)
// }
#endif
