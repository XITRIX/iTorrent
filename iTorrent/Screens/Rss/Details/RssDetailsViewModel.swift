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

class RssDetailsViewModel: BaseViewModelWith<RssItemModel> {
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
        if let link = rssModel.link,
           let magnet = MagnetURI(with: link)
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

        if let link = rssModel.link,
           let file = await TorrentFile(remote: link)
        {
            guard !TorrentService.shared.checkTorrentExists(with: file.infoHashes) else {
                downloadType = .added
                return
            }

            downloadType = .torrent
            download = { [unowned self] in
                navigate(to: TorrentAddViewModel.self, with: .init(torrentFile: file, completion: { [weak self] added in
                    guard added else { return }
                    self?.downloadType = .added
                }), by: .present(wrapInNavigation: true))
            }
            return
        }

        if let link = rssModel.enclosure?.url,
           let file = await TorrentFile(remote: link)
        {
            guard !TorrentService.shared.checkTorrentExists(with: file.infoHashes) else {
                downloadType = .added
                return
            }
            downloadType = .torrent
            download = { [unowned self] in
                navigate(to: TorrentAddViewModel.self, with: .init(torrentFile: file, completion: { [weak self] added in
                    guard added else { return }
                    self?.downloadType = .added
                }), by: .present(wrapInNavigation: true))
            }
            return
        }
    }
}
