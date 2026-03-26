//
//  VLCPlayerViewModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 21.03.2026.
//

import Foundation
import VLCKit
import MvvmFoundation

class VLCPlayerViewModel: BaseViewModelWith<URL>, ObservableObject {
    private(set) var url: URL!
    @Published var showOverlay: Bool = true

    override func prepare(with model: URL) {
        self.url = model
    }

    static func validateURL(_ url: URL) -> Bool {
        guard url.isFileURL else { return false }
        guard url.isFileURL, (try? url.checkResourceIsReachable()) == true else { return false }

        let resourceValues = try? url.resourceValues(forKeys: [.isRegularFileKey])
        return resourceValues?.isRegularFile != false
    }

    static func canOpenInVLC(_ url: URL, timeoutMilliseconds: Int32 = 3_000) async -> VLCMedia? {
        guard validateURL(url), let media = VLCMedia(url: url) else { return nil }

        let parseResult = media.parse(options: .parseLocal, timeout: timeoutMilliseconds)
        guard parseResult == 0 else { return nil }

        let deadline = Date().addingTimeInterval(TimeInterval(timeoutMilliseconds) / 1_000)
        while !media.parsedStatus.isTerminal, Date() < deadline {
            try? await Task.sleep(for: .milliseconds(50))
        }

        guard media.parsedStatus == .done else { return nil }
        if !media.tracksInformation.isEmpty { return media }

        guard media.length.intValue > 0 else { return nil }
        return media
    }
}

extension VLCMediaParsedStatus {
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
