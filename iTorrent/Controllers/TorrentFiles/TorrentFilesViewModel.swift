//
//  TorrentFilesViewModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 21.04.2022.
//

import MVVMFoundation
import TorrentKit

struct TorrentFilesModel {
    let torrent: Torrent
    var fileManager: FileManager?
    var root: DirectoryEntity?
}

class TorrentFilesViewModel: MvvmViewModelWith<TorrentFilesModel> {
    private var model: TorrentFilesModel!
    @Bindable var sections: [SectionModel<FileEntityProtocol>] = []

    override func prepare(with item: MvvmViewModelWith<TorrentFilesModel>.Model) {
        model = item
        if model.root == nil {
            model.fileManager = FileManager(with: model.torrent)
            model.root = model.fileManager?.root
        }

        var files = Array(model.root!.files.values)
        files.sort(by: {
            if type(of: $0) == type(of: $1) {
                return $0.name.lowercased() < $1.name.lowercased()
            }
            return $0 is DirectoryEntity && $1 is FileEntity
        })
        sections = [SectionModel<FileEntityProtocol>.init(items: files)]
    }

    func selectItem(at indexPath: IndexPath) {
        guard var model = model,
            let nextDir = sections[indexPath.section].items[indexPath.row] as? DirectoryEntity
        else { return }

        model.root = nextDir
        navigate(to: TorrentFilesViewModel.self, prepare: model)
    }

    func setTorrentFilePriority(_ priority: TKFileEntry.Priority, at fileIndex: Int) {
        model.torrent.setFilePriority(priority, at: fileIndex)
    }
}
