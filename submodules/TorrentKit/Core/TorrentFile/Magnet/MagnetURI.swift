//
//  MagnetURI.swift
//  TorrentKit
//
//  Created by Даниил Виноградов on 26.04.2022.
//

import Foundation

public extension MagnetURI {
    convenience init?(with url: URL) {
        self.init(unsafeWithMagnetURI: url)
    }
}
