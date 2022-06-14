//
//  Utils+Dataset.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 31.05.2022.
//

import Foundation

extension Utils {
    struct Dataset {
        static var sizes: [(name: String, titles: [UInt], multiplier: UInt)] = {
            var kbSize: [UInt] = []
            for iter in 0...8 {
                kbSize.append(UInt(iter * 128))
            }

            var mbSize: [UInt] = []
            for iter in 0...8 {
                mbSize.append(UInt(iter))
            }

            var res = [(String, [UInt], UInt)]()
            res.append(("KB/S", kbSize, UInt(pow(1024.0, 1))))
            res.append(("MB/S", mbSize, UInt(pow(1024.0, 2))))
            return res
        }()
    }
}
