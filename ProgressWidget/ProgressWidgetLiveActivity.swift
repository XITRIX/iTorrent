//
//  ProgressWidgetLiveActivity.swift
//  ProgressWidget
//
//  Created by Даниил Виноградов on 06.04.2024.
//

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
        ActivityConfiguration(for: ProgressWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack(spacing: 8) {
                HStack {
                    Text(context.attributes.name)
                    Spacer()
                }
                HStack {
                    Text(String("\(context.state.downSpeed.bitrateToHumanReadable)/s ↓"))
                    Text(String(" | "))
                    Text(String("\(context.state.upSpeed.bitrateToHumanReadable)/s ↑"))
                    Spacer()
                    Text(String("\(String(format: "%.2f", context.state.progress * 100))%"))
                }
                .font(.subheadline)
                .foregroundColor(.secondary)

                ProgressView(value: context.state.progress)
                    .progressViewStyle(.linear)
            }
            .widgetURL(URL(string: "iTorrent:hash:\(context.attributes.hash)"))
            .tint(Color(uiColor: tintColor))
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text(String("\(context.state.downSpeed.bitrateToHumanReadable)/s"))
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
                Text(String("\(context.state.downSpeed.bitrateToHumanReadable)/s"))
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
    }
}

//#Preview("Notification", as: .content, using: ProgressWidgetAttributes.preview) {
//    ProgressWidgetLiveActivity()
//} contentStates: {
//    ProgressWidgetAttributes.ContentState(progress: 0.2, downSpeed: 2000, upSpeed: 1000, timeRemainig: "Осталось САСАТБ", timeStamp: .now)
//    ProgressWidgetAttributes.ContentState(progress: 0.7, downSpeed: 12000000, upSpeed: 1000000, timeRemainig: "Осталось САСАТБ", timeStamp: .now)
//}
