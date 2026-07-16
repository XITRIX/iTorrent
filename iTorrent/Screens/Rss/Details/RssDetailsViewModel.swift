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
        case browser
        case added

        var title: String {
            switch self {
            case .magnet:
                %"rss.downloadButtonType.magnet"
            case .torrent:
                %"rss.downloadButtonType.torrent"
            case .browser:
                %"list.add.url.openInBrowser"
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
        if let magnet = MagnetURI(with: rssModel.enclosure?.url) ?? // Check enclosure
                        MagnetURI(with: rssModel.link) // Otherwise check link
        {
            guard !TorrentService.shared.checkTorrentExists(with: magnet.infoHashes) else {
                downloadType = .added
                return
            }

            downloadType = .magnet
            download = { [unowned self] _ in
                TorrentService.shared.addTorrent(by: magnet)
                downloadType = .added
            }
            return
        }


        // MARK: - Try download file
        let remoteURLs = [rssModel.enclosure?.url, rssModel.link]
            .compactMap { $0 }
            .filter { ["http", "https"].contains($0.scheme?.lowercased()) }
        var file: TorrentFile?

        for url in remoteURLs {
            if let downloadedFile = try? await TorrentFile.download(from: url) {
                file = downloadedFile
                break
            }
        }

        if let file {
            guard !TorrentService.shared.checkTorrentExists(with: file.infoHashes) else {
                downloadType = .added
                return
            }

            downloadType = .torrent
            download = { [unowned self] source in
                navigate(to: TorrentAddViewModel.self, with: .init(torrentFile: file, completion: { [weak self] added in
                    guard added else { return }
                    self?.downloadType = .added
                }), by: .present(wrapInNavigation: true, from: source, style: .formSheet))
            }
            return
        }

        if let browserURL = remoteURLs.first {
            downloadType = .browser
            download = { [weak self] _ in
                Task { @MainActor in
                    self?.navigationService?()?.navigate(
                        to: BaseSafariViewController(url: browserURL),
                        by: .present(wrapInNavigation: false)
                    )
                }
            }
        }
    }
}

private extension MagnetURI {
    convenience init?(with url: URL?) {
        guard let url else { return nil }
        self.init(with: url)
    }
}
