//
//  FolderModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 31.03.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import Foundation

class FolderModel {
    var name: String = ""
    var path: URL!
    var size: Int64 = 0
    var downloadedSize: Int64 = 0
    var isPreview: Bool = true
    var files: [FileModel] = []
}
