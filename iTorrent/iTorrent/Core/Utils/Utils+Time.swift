//
//  Utils+Time.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 19.04.2022.
//

import Foundation

extension Utils {
    struct Time {
        public static func downloadingTimeRemainText(speedInBytes: Int64, fileSize: Int64, downloadedSize: Int64) -> String {
            if speedInBytes == 0 {
                return NSLocalizedString("eternity", comment: "")
            }
            let seconds = (fileSize - downloadedSize) / speedInBytes
            return secondsToTimeText(seconds: seconds)
        }

        public static func secondsToTimeText(seconds: Int64) -> String {
            let sec = seconds % 60
            let min = (seconds / 60) % 60
            let hour = (seconds / 60 / 60) % 24
            let day = (seconds / 60 / 60 / 24)

            var res = ""

            if day > 0 {
                res.append(String(day) + "d ")
            }
            if day > 0 || hour > 0 {
                res.append(String(hour) + "h ")
            }
            if day > 0 || hour > 0 || min > 0 {
                res.append(String(min) + "m ")
            }
            if day > 0 || hour > 0 || min > 0 || sec > 0 {
                res.append(String(sec) + "s")
            }

            return res
        }
    }
}
