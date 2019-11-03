//
//  FileInfo.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 18.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation

struct FilePieceData {
    var name: String = ""
    var beginIdx: Int64 = 0
    var endIdx: Int64 = 0
}

class File {
    var name: String = ""
    var path: String = ""
    var size: Int64 = 0
    var downloaded: Int64 = 0
    var isDownloading: Int32 = 0
    var number: Int = 0
    var pieces: [Int32] = []
}

class Folder {
    var name: String = ""
    var size: Int64 = 0
    var files: [File] = []
}
