//
//  TorrentState.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 30.03.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import Foundation
import DeepDiff

public enum TorrentState: String, DiffAware {
    case queued = "Queued"
    case hashing = "Hashing"
    case metadata = "Metadata"
    case downloading = "Downloading"
    case finished = "Finished"
    case seeding = "Seeding"
    case allocating = "Allocating"
    case checkingFastresume = "Checking fastresume"
    case paused = "Paused"
    case null = "NULL"

    init?(id: Int) {
        switch id {
        case 1: self = .queued
        case 2: self = .hashing
        case 3: self = .metadata
        case 4: self = .downloading
        case 5: self = .finished
        case 6: self = .seeding
        case 7: self = .allocating
        case 8: self = .checkingFastresume
        case 9: self = .paused
        default: return nil
        }
    }
}
