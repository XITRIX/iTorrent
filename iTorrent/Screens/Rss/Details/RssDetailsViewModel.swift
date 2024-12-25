//
//  RssDetailsViewModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 08.04.2024.
//

import Combine
import LibTorrent
import MvvmFoundation

extension RssDetailsViewModel {
    enum DownloadType {
        case magnet
        case torrent
        case added

        var title: String {
            switch self {
            case .magnet:
                %"rss.downloadButtonType.magnet"
            case .torrent:
                %"rss.downloadButtonType.torrent"
            case .added:
                %"rss.downloadButtonType.added"
            }
        }
    }
}

final class RssDetailsViewModel: BaseViewModelWith<RssItemModel>, @unchecked Sendable {
    var rssModel: RssItemModel!
    @Published var title: String = ""
    @Published var downloadType: DownloadType?

    override func prepare(with model: RssItemModel) {
        rssModel = model

        title = model.title ?? ""
        Task { await prepareDownload() }
    }

    private(set) var download: (() -> Void)?
}

private extension RssDetailsViewModel {
    func prepareDownload() async {
        // MARK: - Try download magnet
        if let magnet = MagnetURI(with: rssModel.enclosure?.url) ?? // Check enclosure
                        MagnetURI(with: rssModel.link) // Otherwise check link
        {
            guard !TorrentService.shared.checkTorrentExists(with: magnet.infoHashes) else {
                downloadType = .added
                return
            }

            downloadType = .magnet
            download = { [unowned self] in
                TorrentService.shared.addTorrent(by: magnet)
                downloadType = .added
            }
            return
        }


        // MARK: - Try download file
        let file: TorrentFile?

        // Check enclosure
        if let temp = await TorrentFile(remote: rssModel.enclosure?.url) { file = temp }
        // Otherwise check link
        else if let temp = await TorrentFile(remote: rssModel.link) { file = temp }
        // Otherwise nothing to download
        else { file = nil }

        if let file {
            guard !TorrentService.shared.checkTorrentExists(with: file.infoHashes) else {
                downloadType = .added
                return
            }

            downloadType = .torrent
            download = { [unowned self] in
                Task { @MainActor in
                    navigate(to: TorrentAddViewModel.self, with: .init(torrentFile: file, completion: { [weak self] added in
                        guard added else { return }
                        self?.downloadType = .added
                    }), by: .present(wrapInNavigation: true))
                }
            }
            return
        }
    }
}

private extension TorrentFile {
    convenience init?(remote url: URL?) async {
        guard let url else { return nil }
        await self.init(remote: url)
    }
}

private extension MagnetURI {
    convenience init?(with url: URL?) {
        guard let url else { return nil }
        self.init(with: url)
    }
}
