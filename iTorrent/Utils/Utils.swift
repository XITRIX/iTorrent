//
//  Utils.swift
//  iTorrent
//
//  Created by  XITRIX on 15.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class Utils {
    public enum torrentStates : String {
        case Queued = "Queued"
        case Hashing = "Hashing"
        case Metadata = "Metadata"
        case Downloading = "Downloading"
        case Finished = "Finished"
        case Seeding = "Seeding"
        case Allocating = "Allocating"
        case CheckingFastresume = "Checking fastresume"
		case Paused = "Paused"
    }
    
    public static func downloadingTimeRemainText(speedInBytes: Int64, fileSize: Int64, downloadedSize: Int64) -> String {
        if (speedInBytes == 0) {
            return "eternity"
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
        
        if (day > 0) {
            res.append(String(day) + "d ")
        }
        if (day > 0 || hour > 0) {
            res.append(String(hour) + "h ")
        }
        if (day > 0 || hour > 0 || min > 0) {
            res.append(String(min) + "m ")
        }
        if (day > 0 || hour > 0 || min > 0 || sec > 0) {
            res.append(String(sec) + "s")
        }
        
        return res
    }
    
    public static func getSizeText(size: Int64) -> String {
        var size = size
        let names = ["B", "KB", "MB", "GB"]
        var count = 0
        var fRes : Double = 0
        while (count < 3 && size > 1024) {
            size /= 1024
            if (count == 0) {
                fRes = Double(size)
            } else {
                fRes /= 1024
            }
            count+=1;
        }
        let res = count > 1 ? String(format: "%.2f", fRes) : String(size)
        return res + " " + names[count]
    }
    
    public static func checkFolderExist(path: String) {
        if (!FileManager.default.fileExists(atPath: path)) {
            try! FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    public static func createEmptyViewController() -> UIViewController {
        let view = UIViewController()
        view.view.backgroundColor = UIColor(red: 237 / 255, green: 237 / 255, blue: 237 / 255, alpha: 1)
        return view
    }
}
