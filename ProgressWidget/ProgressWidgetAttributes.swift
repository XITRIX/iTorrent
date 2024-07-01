//
//  ProgressWidgetAttributes.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 06.04.2024.
//

#if canImport(ActivityKit)
import ActivityKit
import Foundation

extension ProgressWidgetAttributes {
    enum State: UInt, Codable {
        case checkingFiles
        case downloadingMetadata
        case downloading
        case finished
        case seeding
        case checkingResumeData
        case paused
        case storageError
    }
}

extension ProgressWidgetAttributes.State {
    var name: String {
        switch self {
        case .checkingFiles:
            return %"torrent.state.checkingFiles"
        case .downloadingMetadata:
            return %"torrent.state.fetchingMetadata"
        case .downloading:
            return %"torrent.state.downloading"
        case .finished:
            return %"torrent.state.done"
        case .seeding:
            return %"torrent.state.seeding"
        case .checkingResumeData:
            return %"torrent.state.resuming"
        case .paused:
            return %"torrent.state.paused"
        case .storageError:
            return %"torrent.state.storageError"
        }
    }
}

struct ProgressWidgetAttributes: ActivityAttributes {
    public init(name: String, hash: String) {
        self.name = name
        self.hash = hash
    }

    public struct ContentState: Codable, Hashable {
        public init(state: State, progress: Double, downSpeed: UInt64, upSpeed: UInt64, timeRemainig: String, timeStamp: Date) {
            self.state = state
            self.progress = progress
            self.downSpeed = downSpeed
            self.upSpeed = upSpeed
            self.timeRemainig = timeRemainig
            self.timeStamp = timeStamp
        }

        // Dynamic stateful properties about your activity go here!
        public var state: State
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
#endif
