//
//  TorrentStatus.swift
//  iTorrent
//
//  Created by  XITRIX on 14.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation

class TorrentStatus {
    var title : String = ""
    var state : String = ""
    var displayState : String = ""
    var hash : String = ""
    var creator : String = ""
    var comment : String = ""
    var progress : Float = 0
    var totalWanted : Int64 = 0
    var totalWantedDone : Int64 = 0
    var downloadRate : Int = 0
    var uploadRate : Int = 0
    var totalDownload : Int64 = 0
    var totalUpload : Int64 = 0
    var numSeeds : Int = 0
    var numPeers : Int = 0
    var totalSize : Int64 = 0
    var totalDone : Int64 = 0
    var creationDate : Date?
	var addedDate : Date?
    var isPaused : Bool = false
    var isFinished : Bool = false
    var isSeed : Bool = false
	var seedMode : Bool = false
	var hasMetadata : Bool = false
}
