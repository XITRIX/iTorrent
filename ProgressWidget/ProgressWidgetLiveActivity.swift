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
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ProgressWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack(spacing: 8) {
                HStack {
                    Text(context.attributes.name)
                    Spacer()
                }
                HStack {
                    Text("\(context.state.downSpeed.bitrateToHumanReadable)/s ↓")
                    Text(" | ")
                    Text("\(context.state.upSpeed.bitrateToHumanReadable)/s ↑")
                    Spacer()
                    Text("\(String(format: "%.2f", context.state.progress * 100))%")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)

                ProgressView(value: context.state.progress)
                    .progressViewStyle(.linear)
            }
            .widgetURL(URL(string: "iTorrent:hash:\(context.attributes.hash)"))
            .tint(Color(uiColor: .tintColor))
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("\(context.state.downSpeed.bitrateToHumanReadable)/s")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(String(format: "%.2f", context.state.progress * 100))%").padding(.top, 2)
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
                    .tint(Color(uiColor: .tintColor))
                }
            } compactLeading: {
                Text("\(context.state.downSpeed.bitrateToHumanReadable)/s")
            } compactTrailing: {
                ProgressView(value: context.state.progress)
                    .progressViewStyle(.circular)
                    .tint(Color(uiColor: .tintColor))
            } minimal: {
                ProgressView(value: context.state.progress)
                    .progressViewStyle(.circular)
                    .tint(Color(uiColor: .tintColor))
            }
            .widgetURL(URL(string: "iTorrent:hash:\(context.attributes.hash)"))
            .keylineTint(Color(uiColor: .tintColor))
        }
    }
}

private extension ProgressWidgetAttributes {
    static var preview: ProgressWidgetAttributes {
        ProgressWidgetAttributes(name: "World", hash: "")
    }
}

private extension ProgressWidgetAttributes.ContentState {
    static var smiley: ProgressWidgetAttributes.ContentState {
        ProgressWidgetAttributes.ContentState(progress: 0.2, downSpeed: 2000, upSpeed: 1000, timeRemainig: "Осталось САСАТБ", timeStamp: .now)
    }

    static var starEyes: ProgressWidgetAttributes.ContentState {
        ProgressWidgetAttributes.ContentState(progress: 0.7, downSpeed: 12000000, upSpeed: 1000000, timeRemainig: "Осталось САСАТБ", timeStamp: .now)
    }
}

#Preview("Notification", as: .content, using: ProgressWidgetAttributes.preview) {
    ProgressWidgetLiveActivity()
} contentStates: {
    ProgressWidgetAttributes.ContentState.smiley
    ProgressWidgetAttributes.ContentState.starEyes
}
