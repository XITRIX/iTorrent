//
//  VLCPlayerViewModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 21.03.2026.
//

import Foundation
import MvvmFoundation
import LibTorrent
import SwiftVLC

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

#if !os(visionOS)
    @Published var pipController: PiPController?
#endif

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

    static func canOpenInVLC(_ url: URL, timeoutMilliseconds: Int32 = 3_000) async -> Media? {
        guard validateURL(url), let media = try? Media(url: url) else { return nil }

        do {
            let metadata = try await media.parse(timeout: .milliseconds(Int64(timeoutMilliseconds)))
            if !media.tracks().isEmpty { return media }
            if (metadata.duration ?? media.duration)?.milliseconds ?? 0 > 0 { return media }
            return nil
        } catch {
            return nil
        }
    }

    static func canOpenInVLCSync(_ url: URL, timeoutMilliseconds: Int32 = 100) -> Media? {
        guard validateURL(url), let media = try? Media(url: url) else { return nil }
        return media
    }
}
