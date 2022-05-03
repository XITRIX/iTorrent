//
//  DirectoryEntity.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 22.04.2022.
//

import Foundation

class DirectoryEntity: FileEntityProtocol {
    private let _name: String
    private let _path: String
    private lazy var _size: UInt64 = files.values.map { $0.size }.reduce(0, +)
    var files: [String: FileEntityProtocol] = [:]

    override var size: UInt64 { _size }

    override var name: String { _name }
    override var path: String { _path }

    init(name: String, path: String) {
        self._name = name
        self._path = path
        super.init()
    }
}
