//
//  Utils+Size.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 19.04.2022.
//

import Foundation

extension Utils {
    struct Size {
        public static func getSizeText(size: UInt?, decimals: Int = 2) -> String {
            guard var size = size else {
                return getSizeText(size: 0, decimals: decimals)
            }

            let names = ["B", "KB", "MB", "GB"]
            var count = 0
            var fRes: Double = 0
            while count < 3, size > 1024 {
                size /= 1024
                if count == 0 {
                    fRes = Double(size)
                } else {
                    fRes /= 1024
                }
                count += 1
            }
            let format = "%.\(decimals)f"
            let res = count > 1 ? String(format: format, fRes) : String(size)
            return res + " " + names[count]
        }

        public static func getSpeedLimitText(size: UInt?, decimals: Int = 2) -> String {
            guard size != 0 else { return "Unlimited" }
            return getSizeText(size: size, decimals: decimals).appending("/s")
        }
    }
}
