//
//  Array+MutableForEach.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 08.04.2024.
//

import Foundation

extension Array {
    mutating func mutableForEach(_ body: (inout Element) throws -> Void) rethrows {
        for i in 0 ..< self.count {
            try body(&self[i])
        }
    }
}
