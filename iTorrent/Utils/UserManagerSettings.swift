//
//  UserManagerSettings.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 17.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation

class UserManagerSettings: NSObject, NSCoding {
    private var _totalDownload: Int64 = 0
    private var _totalUpload: Int64 = 0

    var seedMode: Bool = false
    var seedLimit: Int64 = 0
    var addedDate: Date!
    var totalDownloadSession: Int64 = 0
    var totalUploadSession: Int64 = 0
    var zeroSpeedTimeCounter: Int = 0

    var totalDownload: Int64 {
        _totalDownload + totalDownloadSession
    }
    var totalUpload: Int64 {
        _totalUpload + totalUploadSession
    }

    override init() {
        addedDate = Date()
    }

    required init(coder decoder: NSCoder) {
        self.seedMode = decoder.decodeBool(forKey: "seedMode")
        self.seedLimit = decoder.decodeInt64(forKey: "seedLimit")
        self.addedDate = decoder.decodeObject(forKey: "addedDate") as? Date ?? Date()
        self._totalDownload = decoder.decodeInt64(forKey: "totalDownload")
        self._totalUpload = decoder.decodeInt64(forKey: "totalUpload")
    }

    func encode(with coder: NSCoder) {
        coder.encode(seedMode, forKey: "seedMode")
        coder.encode(seedLimit, forKey: "seedLimit")
        coder.encode(addedDate, forKey: "addedDate")
        coder.encode(_totalDownload + totalDownloadSession, forKey: "totalDownload")
        coder.encode(_totalUpload + totalUploadSession, forKey: "totalUpload")
    }
}
