//
//  FileEntity.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 22.04.2022.
//

import Foundation
import TorrentKit
import MVVMFoundation
import ReactiveKit

class FileEntity: FileEntityProtocol {
    let _name: String
    let _size: UInt64
    let id: Int

    override var name: String { _name }
    override var size: UInt64 { _size }

    @Bindable var priority: TKFileEntry.Priority
    @Bindable var downloaded: UInt64 = 0
    @Bindable var progress: Float = 0
    @Bindable var pieces: [Bool] = []

    init(file: TKFileEntry, id: Int) {
        self._name = file.name
        self._size = file.size
        self.priority = file.priority
        self.id = id

        super.init()
        update(with: file)
    }

    func update(with fileEntry: TKFileEntry) {
        $downloaded =? fileEntry.downloaded
        $progress =? (Float(downloaded) / Float(size))
        $pieces =? (progress < 1 ? fileEntry.pieces.map { $0.boolValue } : [true])
    }
}
