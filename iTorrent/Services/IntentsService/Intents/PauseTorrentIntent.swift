//
//  PauseTorrentIntent.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 30.06.2024.
//

import AppIntents

extension NSNotification.Name {
    static var pauseTorrent: Self {
        .init("pauseTorrent")
    }
}

struct PauseTorrentIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "intent.pauseTorrent.title"

    @Parameter(title: "intent.pauseTorrent.hash.title", description: "intent.pauseTorrent.hash.description")
    var torrentHash: String

    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .pauseTorrent, object: torrentHash)
        return .result()
    }
}
