//
//  Data+Hex.swift
//  TorrentKit
//
//  Created by Даниил Виноградов on 18.04.2022.
//

import Foundation

public extension Data {
    var hex: String {
        NSData(data: self).hex()
    }
}
