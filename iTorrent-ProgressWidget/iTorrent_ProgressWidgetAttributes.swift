//
//  iTorrent_ProgressWidgetAttributes.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 15.12.2022.
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
        public init(progress: Double, downSpeed: Int, upSpeed: Int, timeRemainig: String, timeStamp: Date) {
            self.progress = progress
            self.downSpeed = downSpeed
            self.upSpeed = upSpeed
            self.timeRemainig = timeRemainig
            self.timeStamp = timeStamp
        }

        // Dynamic stateful properties about your activity go here!
        public var progress: Double
        public var downSpeed: Int
        public var upSpeed: Int
        public var timeRemainig: String
        public var timeStamp: Date
    }

    // Fixed non-changing properties about your activity go here!
    public var name: String
    public var hash: String
}
