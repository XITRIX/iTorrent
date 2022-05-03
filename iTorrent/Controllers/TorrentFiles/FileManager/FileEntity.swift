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
    private let _name: String
    private let _path: String
    private let _size: UInt64
    
    let index: Int
    let prototype: Bool

    override var name: String { _name }
    override var path: String { _path }
    override var size: UInt64 { _size }

    @Bindable var priority: FileEntry.Priority
    @Bindable var downloaded: UInt64 = 0
    @Bindable var progress: Float = 0
    @Bindable var pieces: [Bool] = []

    init(file: FileEntry, id: Int) {
        self._name = file.name
        self._path = file.path
        self._size = file.size
        self.prototype = file.isPrototype
        self.priority = file.priority
        self.index = id

        super.init()
        update(with: file)
    }

    func update(with fileEntry: FileEntry) {
        $downloaded =? fileEntry.downloaded
        $progress =? (Float(downloaded) / Float(size))
        $pieces =? (progress < 1 ? fileEntry.pieces.map { $0.boolValue } : [true])
    }
}
