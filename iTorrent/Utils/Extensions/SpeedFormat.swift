//
//  SpeedFormat.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 30/10/2023.
//

import Foundation

extension UInt64 {
    var bitrateToHumanReadable: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = .useAll//.subtracting(.useBytes)
        formatter.countStyle = .memory //.decimal
        formatter.allowsNonnumericFormatting = false
        return formatter.string(fromByteCount: Int64(self)).replacingOccurrences(of: "bytes", with: "B")
    }

    var timeString: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: TimeInterval(self))!
    }
}
