//
//  TorrentAddingViewModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 25.04.2022.
//

import MVVMFoundation
import TorrentKit

struct TorrentAddingModel {
    let file: TorrentFile
    var fileManager: AddingFileManager?
    var root: DirectoryEntity?
}

class TorrentAddingViewModel: MvvmViewModelWith<TorrentAddingModel> {
    private var model: TorrentAddingModel!
    private(set) var rootDirectory: Bool = false
    @Bindable var sections: [SectionModel<FileEntityProtocol>] = []

    override func prepare(with item: TorrentAddingModel) {
        model = item

        if model.root == nil {
            rootDirectory = true
            title.value = model.file.name
            model.fileManager = AddingFileManager(with: item.file)
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
        navigate(to: TorrentAddingViewModel.self, prepare: model)
    }

    func setTorrentFilePriority(_ priority: FileEntry.Priority, at fileIndex: Int) {
        model.fileManager?.rawFiles[fileIndex].priority = priority
    }

    func setTorrentDictionaryPriority(_ priority: FileEntry.Priority, at directoryIndex: Int) {
        getDirectory(at: directoryIndex)?.getRawFiles().forEach { $0.priority = priority }
    }

    func setAllTorrentFilesPriority(_ priority: FileEntry.Priority) {
        model.fileManager?.rawFiles.forEach { $0.priority = priority }
    }

    func getFile(at index: Int) -> FileEntity? {
        sections.first?.items[index] as? FileEntity
    }

    func getDirectory(at index: Int) -> DirectoryEntity? {
        sections.first?.items[index] as? DirectoryEntity
    }

    func download() {
        (MVVM.resolve() as TorrentManager).addTorrent(model.file)
        dismiss()
    }
}
