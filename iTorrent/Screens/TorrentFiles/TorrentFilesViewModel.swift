//
//  TorrentFilesViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 01/11/2023.
//

import LibTorrent
import MvvmFoundation

class TorrentFilesViewModel: BaseViewModelWith<TorrentHandle> {
    private var torrentHandle: TorrentHandle!

    @Published var sections: [MvvmCollectionSectionModel] = []

    override func prepare(with model: TorrentHandle) {
        torrentHandle = model

        reload(with: model)
        disposeBag.bind {
            torrentHandle.updatePublisher
                .sink { [unowned self] handle in
                    reload(with: handle)
                }
        }
    }
}

private extension TorrentFilesViewModel {
    func reload(with torrentHandle: TorrentHandle) {
        let oldItems = sections.first?.items.map { $0 as? TorrentFilesItemViewModel }.compactMap { $0 } ?? []

        let items = torrentHandle.files.map { file in
            if let item = oldItems.first(where: { $0.file.path == file.path }) {
                item.prepare(with: file)
                return item
            }
            return TorrentFilesItemViewModel(with: file)
        }

        self.sections = [.init(id: "files", style: .plain, items: items)]
    }
}
