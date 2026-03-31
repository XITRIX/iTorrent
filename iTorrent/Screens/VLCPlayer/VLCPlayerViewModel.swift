//
//  VLCPlayerViewModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 21.03.2026.
//

import Foundation
import VLCKit
import MvvmFoundation
import LibTorrent

extension VLCPlayerViewModel {
    struct Config {
        let url: URL
        let torrentPair: (handle: TorrentHandle, fileIndex: Int)?
    }
}

class VLCPlayerViewModel: BaseViewModelWith<VLCPlayerViewModel.Config>, ObservableObject {
    private(set) var url: URL!
    private(set) var torrentPair: (handle: TorrentHandle, fileIndex: Int)?

    @Published var showOverlay: Bool = true
    @Published var segmentedProgress: [Double]?

    override func prepare(with model: Config) {
        self.url = model.url
        self.torrentPair = model.torrentPair
        binding()
    }

    private func binding() {
        guard let torrentPair else { return }
        refreshSegmentedProgress()
        disposeBag.bind {
            torrentPair.handle.updatePublisher.sink { [weak self] update in
                guard let self else { return }
                refreshSegmentedProgress()
            }
        }
    }

    private func refreshSegmentedProgress() {
        guard let torrentPair else { return }
        let file = torrentPair.handle.snapshot.files[torrentPair.fileIndex]
        segmentedProgress = file.segmentedProgress
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

    static func canOpenInVLCSync(_ url: URL, timeoutMilliseconds: Int32 = 100) -> VLCMedia? {
        guard validateURL(url), let media = VLCMedia(url: url) else { return nil }

        let parseResult = media.parse(options: .parseLocal, timeout: timeoutMilliseconds)
        guard parseResult == 0 else { return nil }

        let deadline = Date().addingTimeInterval(TimeInterval(timeoutMilliseconds) / 1_000)
        while !media.parsedStatus.isTerminal, Date() < deadline {
            Thread.sleep(forTimeInterval: 50 / 1_000)
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
