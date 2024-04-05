//
//  ProgressWidgetAttributes.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 06.04.2024.
//

import ActivityKit
import Foundation

struct ProgressWidgetAttributes: ActivityAttributes {
    public init(name: String, hash: String) {
        self.name = name
        self.hash = hash
    }

    public struct ContentState: Codable, Hashable {
        public init(progress: Double, downSpeed: UInt64, upSpeed: UInt64, timeRemainig: String, timeStamp: Date) {
            self.progress = progress
            self.downSpeed = downSpeed
            self.upSpeed = upSpeed
            self.timeRemainig = timeRemainig
            self.timeStamp = timeStamp
        }

        // Dynamic stateful properties about your activity go here!
        public var progress: Double
        public var downSpeed: UInt64
        public var upSpeed: UInt64
        public var timeRemainig: String
        public var timeStamp: Date
    }

    // Fixed non-changing properties about your activity go here!
    public var name: String
    public var hash: String
}
