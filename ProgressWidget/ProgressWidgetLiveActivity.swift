//
//  ProgressWidgetLiveActivity.swift
//  ProgressWidget
//
//  Created by Даниил Виноградов on 06.04.2024.
//

#if canImport(ActivityKit)
import ActivityKit
import SwiftUI
import WidgetKit

struct ProgressWidgetLiveActivity: Widget {
    static var userDefaults: UserDefaults { UserDefaults(suiteName: "group.itorrent.life-activity") ?? .standard }

    var tintColor: UIColor {
        guard let data = Self.userDefaults.data(forKey: "preferencesTintColor")
        else { return .tintColor }
        return (try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data)) ?? .tintColor
    }

    var body: some WidgetConfiguration {
        let config = ActivityConfiguration(for: ProgressWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
#if swift(>=6)
            if #available(iOSApplicationExtension 18, *) {
                ProgressWidgetLiveActivityWatchSupportContent(context: context)
                    .tint(Color(uiColor: tintColor))
                    .padding()
            } else {
#endif
                ProgressWidgetLiveActivityContent(context: context)
                    .tint(Color(uiColor: tintColor))
                    .padding()
#if swift(>=6)
            }
#endif
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    LeadingView(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(String("\(String(format: "%.2f", context.state.progress * 100))%")).padding(.top, 2)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack {
                        HStack {
                            Text(context.attributes.name).padding(.top, 2)
                            Spacer()
                            Text(context.state.timeRemainig)
                        }
                        ProgressView(value: context.state.progress)
                            .progressViewStyle(.linear)
                            .padding([.leading, .trailing], 8)
                    }
                    .tint(Color(uiColor: tintColor))
                }
            } compactLeading: {
                LeadingView(context: context)
            } compactTrailing: {
                ProgressView(value: context.state.progress)
                    .progressViewStyle(.circular)
                    .tint(Color(uiColor: tintColor))
            } minimal: {
                ProgressView(value: context.state.progress)
                    .progressViewStyle(.circular)
                    .tint(Color(uiColor: tintColor))
            }
            .widgetURL(URL(string: "iTorrent:hash:\(context.attributes.hash)"))
            .keylineTint(Color(uiColor: tintColor))
        }

#if swift(>=6)
        if #available(iOS 18.0, *) {
            return config.supplementalActivityFamilies([.small])
        } else {
#endif
            return config
#if swift(>=6)
        }
#endif
    }

}

#if swift(>=6)
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
                    Text(context.attributes.name)
                        .font(.caption)
                    Spacer()
                }
                HStack {
                    switch context.state.state {
                    case .checkingFiles:
                        Text(context.state.state.name)
                    case .downloadingMetadata:
                        Text(context.state.state.name)
                    case .downloading:
                            Text(String("\(context.state.downSpeed.bitrateToHumanReadable)/s ↓"))
                            Spacer()
                            Text(String("\(context.state.upSpeed.bitrateToHumanReadable)/s ↑"))
                    case .finished:
                        Text(context.state.state.name)
                    case .seeding:
                        Text(context.state.state.name)
                    case .checkingResumeData:
                        Text(context.state.state.name)
                    case .paused:
                        Text(context.state.state.name)
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
                case .checkingResumeData:
                    Text(context.state.state.name)
                case .paused:
                    Text(context.state.state.name)
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
            Image(systemName: "arrow.up.to.line")
        case .checkingResumeData:
            Image(systemName: "arrow.triangle.2.circlepath")
        case .paused:
            Image(systemName: "pause.fill")
        }
    }
}

//#Preview("Progress", 
//         as: .dynamicIsland(.compact),
//         using: ProgressWidgetAttributes(name: "Test torrent", hash: "")
//) {
//    ProgressWidgetLiveActivity()
//} contentStates: {
//    ProgressWidgetAttributes.ContentState(progress: 0.2, downSpeed: 2000, upSpeed: 1000, timeRemainig: "Осталось САСАТБ", timeStamp: .now)
//}

//#Preview("Notification", as: .content, using: ProgressWidgetAttributes(name: "Test torrent", hash: "")) {
//    ProgressWidgetLiveActivity()
//} contentStates: {
//    ProgressWidgetAttributes.ContentState(progress: 0.2, downSpeed: 2000, upSpeed: 1000, timeRemainig: "Осталось САСАТБ", timeStamp: .now)
//    ProgressWidgetAttributes.ContentState(progress: 0.7, downSpeed: 12000000, upSpeed: 1000000, timeRemainig: "Осталось САСАТБ", timeStamp: .now)
//}
#endif
