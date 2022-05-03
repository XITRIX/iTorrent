//
//  FileManager.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 22.04.2022.
//

import Foundation
import ReactiveKit
import MVVMFoundation
import TorrentKit

class FileManager {
    let rawFiles: [FileEntity]
    let root: DirectoryEntity

    private let bag = DisposeBag()

    deinit {
        print("FileManager deinit")
    }

    init(with torrent: TorrentHandle) {
        let root = DirectoryEntity(name: "", path: "")
        var rawFiles = [FileEntity]()

        let files = torrent.files
        for fileNum in files.enumerated() {
            let file = fileNum.element
            let parts = file.path.split(separator: "/")
            var currentDirectory = root
            for part in parts {
                let part = String(part)

                // If path part equals file name - it's file
                if part == file.name {
                    let fileEntity = FileEntity(file: file, id: fileNum.offset)
                    currentDirectory.files[part] = fileEntity
                    rawFiles.append(fileEntity)
                    break
                }

                // Create and move to next folder
                var nextDir: DirectoryEntity? = currentDirectory.files[part] as? DirectoryEntity
                if nextDir == nil {
                    nextDir = DirectoryEntity(name: part, path: "\(currentDirectory.path)/\(part)")
                    currentDirectory.files[part] = nextDir
                }
                currentDirectory = nextDir!
            }
        }

        self.rawFiles = rawFiles.sorted(by: { $0.index < $1.index })

        if root.files.values.count == 1,
           let first = root.files.values.first as? DirectoryEntity,
           first.name == torrent.name
        {
            self.root = first
        } else {
            self.root = root
        }

        // Binding
        torrent.rx.progress.throttle(for: 0.5).observeNext { _ in
            for file in torrent.files.enumerated() {
                DispatchQueue.main.async {
                    rawFiles[file.offset].update(with: file.element)
                }
            }
        }.dispose(in: bag)
    }

    func setAllFilesPriority(_ priority: FileEntry.Priority) {
        rawFiles.forEach { $0.priority = priority }
    }
}
