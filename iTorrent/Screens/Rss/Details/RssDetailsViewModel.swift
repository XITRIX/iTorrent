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

class RssDetailsViewModel: BaseViewModelWith<RssItemModel>, @unchecked Sendable {
    var rssModel: RssItemModel!
    @Published var title: String = ""
    @Published var downloadType: DownloadType?

    override func prepare(with model: RssItemModel) {
        rssModel = model

        title = model.title ?? ""
        Task { await prepareDownload() }
    }

    private(set) var download: ((_ from: MvvmPresentationSource?) -> Void)?
}

private extension RssDetailsViewModel {
    func prepareDownload() async {
        // MARK: - Try download magnet
        if let magnetSource = [rssModel.enclosure?.url, rssModel.link]
            .compactMap({ url -> TorrentSession.Source? in
                guard let url else { return nil }
                return TorrentSession.Source(magnetURL: url)
            })
            .first
        {
            guard !TorrentService.shared.checkTorrentExists(with: magnetSource.infoHashes) else {
                downloadType = .added
                return
            }

            downloadType = .magnet
            download = { [unowned self] _ in
                TorrentService.shared.addTorrent(magnetSource)
                downloadType = .added
            }
            return
        }

        // MARK: - Try download file
        let preview: TorrentSession.AddPreview?

        // Check enclosure
        if let temp = await TorrentSession.AddPreview(remote: rssModel.enclosure?.url) { preview = temp }
        // Otherwise check link
        else if let temp = await TorrentSession.AddPreview(remote: rssModel.link) { preview = temp }
        // Otherwise nothing to download
        else { preview = nil }

        if let preview {
            guard !TorrentService.shared.checkTorrentExists(with: preview.infoHashes) else {
                downloadType = .added
                return
            }

            downloadType = .torrent
            download = { [unowned self] source in
                navigate(to: TorrentAddViewModel.self, with: .init(preview: preview, completion: { [weak self] added in
                    guard added else { return }
                    self?.downloadType = .added
                }), by: .present(wrapInNavigation: true, from: source, style: .formSheet))
            }
            return
        }
    }
}

private extension TorrentSession.AddPreview {
    convenience init?(remote url: URL?) async {
        guard let url else { return nil }
        await self.init(remote: url)
    }
}

