//
//  TorrentFilesViewModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 21.04.2022.
//

import MVVMFoundation
import TorrentKit

struct TorrentFilesModel {
    let torrent: TorrentHandle
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

    func setPriority(_ priority: FileEntry.Priority, at indexPath: IndexPath) {
        switch sections[indexPath.section].items[indexPath.row] {
        case is DirectoryEntity:
            setTorrentDictionaryPriority(priority, at: indexPath.row)
        case let file as FileEntity:
            setTorrentFilePriority(priority, at: file.index)
        default: break
        }
    }

    private func setTorrentFilePriority(_ priority: FileEntry.Priority, at fileIndex: Int) {
        model.torrent.setFilePriority(priority, at: fileIndex)
        model.fileManager?.rawFiles[fileIndex].priority = priority
    }

    private func setTorrentDictionaryPriority(_ priority: FileEntry.Priority, at dictionaryIndex: Int) {
        guard let dict = getDirectory(at: dictionaryIndex)
        else { return }

        for file in dict.getRawFiles() {
            model.torrent.setFilePriority(priority, at: file.index)
            file.priority = priority
        }
    }

    func setAllTorrentFilesPriority(_ priority: FileEntry.Priority) {
        let priorities = Array(repeating: NSNumber(value: priority.rawValue), count: model.fileManager?.rawFiles.count ?? 0)
        model.torrent.setFilesPriority(priorities)
        model.fileManager?.rawFiles.forEach { $0.priority = priority }
    }

    func getDirectory(at index: Int) -> DirectoryEntity? {
        sections.first?.items[index] as? DirectoryEntity
    }

    func getFile(at index: Int) -> FileEntity? {
        sections.first?.items[index] as? FileEntity
    }
}

extension DirectoryEntity {
    func getRawFiles() -> [FileEntity] {
        var res = [FileEntity]()
        files.values.forEach {
            switch $0 {
            case let file as FileEntity:
                res.append(file)
            case let directory as DirectoryEntity:
                res.append(contentsOf: directory.getRawFiles())
            default: break
            }
        }
        return res
    }
}
