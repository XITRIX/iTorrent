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
    public enum torrentStates : String, CaseIterable {
        case Queued = "Queued"
        case Hashing = "Hashing"
        case Metadata = "Metadata"
        case Downloading = "Downloading"
        case Finished = "Finished"
        case Seeding = "Seeding"
        case Allocating = "Allocating"
        case CheckingFastresume = "Checking fastresume"
		case Paused = "Paused"
        
        init?(id : Int) {
            switch id {
            case 1: self = .Queued
            case 2: self = .Hashing
            case 3: self = .Metadata
            case 4: self = .Downloading
            case 5: self = .Finished
            case 6: self = .Seeding
            case 7: self = .Allocating
            case 8: self = .CheckingFastresume
            case 9: self = .Paused
            default: return nil
            }
        }
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
	
	public static func getWiFiAddress() -> String? {
		var address : String?
		
		// Get list of all interfaces on the local machine:
		var ifaddr : UnsafeMutablePointer<ifaddrs>?
		guard getifaddrs(&ifaddr) == 0 else { return nil }
		guard let firstAddr = ifaddr else { return nil }
		
		// For each interface ...
		for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
			let interface = ifptr.pointee
			
			// Check for IPv4 or IPv6 interface:
			let addrFamily = interface.ifa_addr.pointee.sa_family
			if addrFamily == UInt8(AF_INET) {//} || addrFamily == UInt8(AF_INET6) {
				
				// Check interface name:
				let name = String(cString: interface.ifa_name)
				if  name == "en0" {
					
					// Convert interface address to a human readable string:
					var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
					getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
								&hostname, socklen_t(hostname.count),
								nil, socklen_t(0), NI_NUMERICHOST)
					address = String(cString: hostname)
				}
			}
		}
		freeifaddrs(ifaddr)
		
		return address
	}
}
