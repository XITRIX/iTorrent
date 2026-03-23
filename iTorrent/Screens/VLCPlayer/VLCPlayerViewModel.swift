//
//  VLCPlayerViewModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 21.03.2026.
//

import Foundation
import VLCKit
import MvvmFoundation

class VLCPlayerViewModel: BaseViewModelWith<URL> {
    private(set) var url: URL!

    override func prepare(with model: URL) {
        self.url = model
    }

    static func validateURL(_ url: URL) -> Bool {
        guard url.isFileURL else { return false }
        guard url.isFileURL, (try? url.checkResourceIsReachable()) == true else { return false }

        let resourceValues = try? url.resourceValues(forKeys: [.isRegularFileKey])
        return resourceValues?.isRegularFile != false
    }

    static func canOpenInVLC(_ url: URL, timeoutMilliseconds: Int32 = 3_000) async -> Bool {
        guard validateURL(url), let media = VLCMedia(url: url) else { return false }

        let parseResult = media.parse(options: .parseLocal, timeout: timeoutMilliseconds)
        guard parseResult == 0 else { return false }

        let deadline = Date().addingTimeInterval(TimeInterval(timeoutMilliseconds) / 1_000)
        while !media.parsedStatus.isTerminal, Date() < deadline {
            try? await Task.sleep(for: .milliseconds(50))
        }

        guard media.parsedStatus == .done else { return false }
        if !media.tracksInformation.isEmpty { return true }

        return media.length.intValue > 0
    }
}

private extension VLCMediaParsedStatus {
    var isTerminal: Bool {
        switch self {
        case .skipped, .failed, .timeout, .cancelled, .done:
            return true
        case .`init`, .pending:
            return false
        @unknown default:
            return false
        }
    }
}
