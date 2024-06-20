//
//  RssDetailsViewModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 08.04.2024.
//

import Combine
import LibTorrent
import MvvmFoundation

class RssDetailsViewModel: BaseViewModelWith<RssItemModel> {
    var rssModel: RssItemModel!
    @Published var title: String = ""

    override func prepare(with model: RssItemModel) {
        rssModel = model

        title = model.title ?? ""
        Task { await tryDownload() }
    }
}

private extension RssDetailsViewModel {
    func tryDownload() async {
        if let magnet = MagnetURI(with: rssModel.link),
           !TorrentService.shared.checkTorrentExists(with: magnet.infoHashes)
        {
            alert(title: %"rssdetail.magnetFound", actions: [
                .init(title: %"common.cancel", style: .cancel),
                .init(title: %"common.download", style: .default) {
                    TorrentService.shared.addTorrent(by: magnet)
                }
            ])
        } else if let file = await TorrentFile(remote: rssModel.link),
                  !TorrentService.shared.checkTorrentExists(with: file.infoHashes)
        {
            alert(title: %"rssdetail.torrentFound", actions: [
                .init(title: %"common.cancel", style: .cancel),
                .init(title: %"common.download", style: .default) { [unowned self] in
                    navigate(to: TorrentAddViewModel.self, with: .init(torrentFile: file), by: .present(wrapInNavigation: true))
                }
            ])
        }
    }
}
