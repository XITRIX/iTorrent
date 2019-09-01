//
//  UserManagerSettings.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 17.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation

class UserManagerSettings : NSObject, NSCoding  {
	var seedMode : Bool = false
	var seedLimit : Int64 = 0
	var addedDate : Date!
    var totalDownload : Int64 = 0
    var totalDownloadSession : Int64 = 0
    var totalUpload : Int64 = 0
    var totalUploadSession : Int64 = 0
	
	override init() {
		addedDate = Date()
	}
	
	required init(coder decoder: NSCoder) {
		self.seedMode = decoder.decodeBool(forKey: "seedMode")
		self.seedLimit = decoder.decodeInt64(forKey: "seedLimit")
		self.addedDate = decoder.decodeObject(forKey: "addedDate") as? Date ?? Date()
        self.totalDownload = decoder.decodeInt64(forKey: "totalDownload")
        self.totalUpload = decoder.decodeInt64(forKey: "totalUpload")
	}
	
	func encode(with coder: NSCoder) {
		coder.encode(seedMode, forKey: "seedMode")
		coder.encode(seedLimit, forKey: "seedLimit")
		coder.encode(addedDate, forKey: "addedDate")
        coder.encode(totalDownload + totalDownloadSession, forKey: "totalDownload")
        coder.encode(totalUpload + totalUploadSession, forKey: "totalUpload")
	}
}
