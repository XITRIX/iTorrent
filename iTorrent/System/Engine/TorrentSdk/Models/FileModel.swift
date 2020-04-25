//
//  FileModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 30.03.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import Foundation

class FileModel {
    enum TorrentDownloadPriority: Int {
        case dontDownload = 0
        case lowPriority = 1
        case mediumPriority = 4
        case normalPriority = 7
    }
    
    var name: String
    var path: URL
    var size: Int64
    var priority: TorrentDownloadPriority
    var downloadedBytes: Int64!
    var beginIdx: Int64!
    var endIdx: Int64!
    var pieces: [Int]!
    
    var isPreview: Bool
    
    init(file: File, isPreview: Bool = false) {
        self.isPreview = isPreview
        
        let filePath = String(validatingUTF8: file.file_name) ?? "ERROR"
        path = URL(string: "/" + filePath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)!
        name = path.lastPathComponent
        size = file.file_size
        priority = TorrentDownloadPriority(rawValue: Int(file.file_priority)) ?? .dontDownload
        if !isPreview {
            downloadedBytes = file.file_downloaded
            beginIdx = file.begin_idx
            endIdx = file.end_idx
            let arr = Array(UnsafeBufferPointer(start: file.pieces, count: Int(file.num_pieces)))
            pieces = arr.map({Int($0)})
        }
    }
    
    func update(with file: FileModel) {
        //name = file.name
        //size = file.size
        downloadedBytes = file.downloadedBytes
        //priority = file.priority
        //beginIdx = file.beginIdx
        //endIdx = file.endIdx
        pieces = file.pieces
    }
}
