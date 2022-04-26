//
//  TorrentFile.swift
//  TorrentKit
//
//  Created by Даниил Виноградов on 26.04.2022.
//

import Foundation

public extension TorrentFile {
    convenience init?(with file: URL) {
        self.init(unsafeWithFileAt: file)
        if !isValid { return nil }
    }

    convenience init?(with data: Data) {
        self.init(unsafeWithFileWith: data)
        if !isValid { return nil }
    }
}
