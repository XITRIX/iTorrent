//
//  iTorrent_ProgressWidgetLiveActivity.swift
//  iTorrent-ProgressWidget
//
//  Created by Даниил Виноградов on 21.11.2022.
//  Copyright © 2022  XITRIX. All rights reserved.
//

import ActivityKit
import WidgetKit
import SwiftUI

public struct iTorrent_ProgressWidgetAttributes: ActivityAttributes {
    public init(name: String, hash: String) {
        self.name = name
        self.hash = hash
    }

    public struct ContentState: Codable, Hashable {
        public init(progress: Double, speed: Int, timeRemainig: String, timeStamp: Date) {
            self.progress = progress
            self.speed = speed
            self.timeRemainig = timeRemainig
            self.timeStamp = timeStamp
        }

        // Dynamic stateful properties about your activity go here!
        public var progress: Double
        public var speed: Int
        public var timeRemainig: String
        public var timeStamp: Date
    }

    // Fixed non-changing properties about your activity go here!
    public var name: String
    public var hash: String
}

@available(iOS 16.1, *)
struct iTorrent_ProgressWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: iTorrent_ProgressWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                HStack {
                    Text(context.attributes.name)
                    Spacer()
                    Text("\(String(format: "%.2f", context.state.progress * 100))%")
                }
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
                    Text(context.state.timeRemainig)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(Utils.getSizeText(size: Int64(context.state.speed)))/s")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack {
                        Text(context.attributes.name).padding(.top, 2)
                        ProgressView(value: context.state.progress)
                            .progressViewStyle(.linear)
                    }
                    .tint(Color(uiColor: .mainColor))
                }
            } compactLeading: {
                ProgressView(value: context.state.progress)
                    .progressViewStyle(.circular)
                    .tint(Color(uiColor: .mainColor))
//                Text("\(String(format: "%.2f", context.state.progress * 100))%")
            } compactTrailing: {
                Text("\(Utils.getSizeText(size: Int64(context.state.speed)))/s")
            } minimal: {
                Text("\(String(format: "%.2f", context.state.progress * 100))%")
            }
            .widgetURL(URL(string: "iTorrent:hash:\(context.attributes.hash)"))
            .keylineTint(Color(uiColor: .mainColor))
        }
    }
}

