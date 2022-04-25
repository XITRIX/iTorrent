//
//  AddingFileManager.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 25.04.2022.
//

import Foundation
import ReactiveKit
import TorrentKit

class AddingFileManager {
    let rawFiles: [FileEntity]
    let root: DirectoryEntity

    private let bag = DisposeBag()

    deinit {
        print("FileManager deinit")
    }

    init(with file: TorrentFile) {
        let files = file.files
        let root = DirectoryEntity(name: "")
        var rawFiles = [FileEntity]()

        for fileNum in files.enumerated() {
            let file = fileNum.element
            let parts = file.path.split(separator: "/")
            var currentDirectory = root
            for part in parts {
                let part = String(part)

                if let lastPart = parts.last,
                   part == lastPart
                {
                    let fileEntity = FileEntity(file: file, id: fileNum.offset)
                    currentDirectory.files[part] = fileEntity
                    rawFiles.append(fileEntity)
                    break
                }

                // Create and move to next folder
                var nextDir: DirectoryEntity? = currentDirectory.files[part] as? DirectoryEntity
                if nextDir == nil {
                    nextDir = DirectoryEntity(name: part)
                    currentDirectory.files[part] = nextDir
                }
                currentDirectory = nextDir!
            }
        }

        self.rawFiles = rawFiles.sorted(by: { $0.id < $1.id })

        if root.files.values.count == 1,
           let first = root.files.values.first as? DirectoryEntity,
           first.name == file.name
        {
            self.root = first
        } else {
            self.root = root
        }
    }
}
