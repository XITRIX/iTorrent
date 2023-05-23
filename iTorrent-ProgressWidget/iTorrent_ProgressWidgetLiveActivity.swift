//
//  iTorrent_ProgressWidgetLiveActivity.swift
//  iTorrent-ProgressWidget
//
//  Created by Даниил Виноградов on 21.11.2022.
//  Copyright © 2022  XITRIX. All rights reserved.
//

import ActivityKit
import SwiftUI
import WidgetKit

@available(iOS 16.1, *)
struct Test: View {
    @State var timeRemaining = 10
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Text("\(timeRemaining)")
            .onReceive(timer) { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                }
            }
    }
}

@available(iOS 16.1, *)
struct Test2: View {
    @State var progress: Double

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { _ in
            Text("\(String(format: "%.2f", progress * 100))%")
        }
    }
}

@available(iOS 16.1, *)
struct iTorrent_ProgressWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: iTorrent_ProgressWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack(spacing: 8) {
                HStack {
                    Text(context.attributes.name)
                    Spacer()
//                    Test()

//                    TimelineView(.periodic(from: .now, by: 1.0)) { timeline in
//                        Text("\(String(format: "%.2f", updaterViewModel.progress * 100))%")
//                    }
//                    Test2(updaterViewModel: .init(hash: context.attributes.hash))
//                    Text(.now + 200, style: .timer)
                }
                HStack {
                    Text("\(Utils.getSizeText(size: Int64(context.state.downSpeed)))/s ↓")
                    Text(" | ")
                    Text("\(Utils.getSizeText(size: Int64(context.state.upSpeed)))/s ↑")
                    Spacer()
                    Text("\(String(format: "%.2f", context.state.progress * 100))%")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)

                ProgressView(value: context.state.progress)
                    .progressViewStyle(.linear)
            }
            .widgetURL(URL(string: "iTorrent:hash:\(context.attributes.hash)"))
            .tint(Color(uiColor: .mainColor))
            .padding()
//            .activityBackgroundTint(Color.cyan)
//            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("\(Utils.getSizeText(size: Int64(context.state.downSpeed)))/s")
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
                    .tint(Color(uiColor: .mainColor))
                }
            } compactLeading: {
                Text("\(Utils.getSizeText(size: Int64(context.state.downSpeed)))/s")
//                Text("\(String(format: "%.2f", context.state.progress * 100))%")
            } compactTrailing: {
                ProgressView(value: context.state.progress)
                    .progressViewStyle(.circular)
                    .tint(Color(uiColor: .mainColor))
            } minimal: {
                ProgressView(value: context.state.progress)
                    .progressViewStyle(.circular)
                    .tint(Color(uiColor: .mainColor))
            }
            .widgetURL(URL(string: "iTorrent:hash:\(context.attributes.hash)"))
            .keylineTint(Color(uiColor: .mainColor))
        }
    }
}

@available(iOSApplicationExtension 16.2, *)
struct LiveActivityWidgetExtensionLiveActivity_Previews: PreviewProvider {
    static let attributes = iTorrent_ProgressWidgetAttributes(name: "Naruto", hash: "")
    static let contentState = iTorrent_ProgressWidgetAttributes.ContentState(progress: 0.5, downSpeed: 1500300, upSpeed: 53000, timeRemainig: "10 min", timeStamp: Date())

    static var previews: some View {
        attributes
            .previewContext(contentState, viewKind: .dynamicIsland(.compact))
            .previewDisplayName("Island Compact")
        attributes
            .previewContext(contentState, viewKind: .dynamicIsland(.expanded))
            .previewDisplayName("Island Expanded")
        attributes
            .previewContext(contentState, viewKind: .dynamicIsland(.minimal))
            .previewDisplayName("Minimal")
        attributes
            .previewContext(contentState, viewKind: .content)
            .previewDisplayName("Notification")
    }
}
