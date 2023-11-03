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
        let newFiles = torrentHandle.files

        guard oldItems.count != newFiles.count else {
            return oldItems.enumerated().forEach { item in
                item.element.prepare(with: newFiles[item.offset])
            }
        }

        let items = torrentHandle.files.map { TorrentFilesItemViewModel(with: $0) }
        self.sections = [.init(id: "files", style: .plain, items: items)]
    }
}
