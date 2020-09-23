//
//  Utils.swift
//  iTorrent
//
//  Created by  XITRIX on 15.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import ITorrentFramework
import UIKit

class Utils {
    public static func interfaceNames() -> [String] {
        let MAX_INTERFACES = 128

        var interfaceNames = [String]()
        let interfaceNamePtr = UnsafeMutablePointer<Int8>.allocate(capacity: Int(IF_NAMESIZE))
        for interfaceIndex in 1 ... MAX_INTERFACES {
            if if_indextoname(UInt32(interfaceIndex), interfaceNamePtr) != nil {
                let interfaceName = String(cString: interfaceNamePtr)
                interfaceNames.append(interfaceName)
            } else {
                break
            }
        }

        interfaceNamePtr.deallocate()
        return interfaceNames
    }

    public static var topViewController: UIViewController? {
        var vc = UIApplication.shared.keyWindow?.rootViewController
        while vc?.presentedViewController != nil {
            vc = vc?.presentedViewController
        }
        return vc
    }

    public static var rootViewController: UIViewController {
        UIApplication.shared.keyWindow!.rootViewController!
    }

    public static var mainStoryboard: UIStoryboard = {
        UIStoryboard(name: "Main", bundle: nil)
    }()

    public static func instantiate<T: UIViewController>(_ viewController: String) -> T {
        mainStoryboard.instantiateViewController(withIdentifier: viewController) as! T
    }

    public static func instantiateNavigationController(_ rootViewController: UIViewController? = nil) -> UINavigationController {
        let nvc = instantiate("NavigationController") as UINavigationController
        if let vc = rootViewController {
            nvc.viewControllers = [vc]
        }
        return nvc
    }

    public static func downloadingTimeRemainText(speedInBytes: Int64, fileSize: Int64, downloadedSize: Int64) -> String {
        if speedInBytes == 0 {
            return NSLocalizedString("eternity", comment: "")
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

        if day > 0 {
            res.append(String(day) + "d ")
        }
        if day > 0 || hour > 0 {
            res.append(String(hour) + "h ")
        }
        if day > 0 || hour > 0 || min > 0 {
            res.append(String(min) + "m ")
        }
        if day > 0 || hour > 0 || min > 0 || sec > 0 {
            res.append(String(sec) + "s")
        }

        return res
    }

    public static func getSizeText(size: Int64?, decimals: Bool = false) -> String {
        guard var size = size else {
            return getSizeText(size: 0, decimals: decimals)
        }

        let names = ["B", "KB", "MB", "GB"]
        var count = 0
        var fRes: Double = 0
        while count < 3, size > 1024 {
            size /= 1024
            if count == 0 {
                fRes = Double(size)
            } else {
                fRes /= 1024
            }
            count += 1
        }
        let format = decimals ? "%.0f" : "%.2f"
        let res = count > 1 ? String(format: format, fRes) : String(size)
        return res + " " + names[count]
    }

    public static func checkFolderExist(path: String) {
        if !FileManager.default.fileExists(atPath: path) {
            try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
    }

    public static func createEmptyViewController() -> UIViewController {
        let view = ThemedUIViewController()
        return view
    }

    public static func getWiFiAddress() -> String? {
        var address: String?

        // Get list of all interfaces on the local machine:
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else {
            return nil
        }
        guard let firstAddr = ifaddr else {
            return nil
        }

        // For each interface ...
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee

            // Check for IPv4 or IPv6 interface:
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) { // } || addrFamily == UInt8(AF_INET6) {
                // Check interface name:
                let name = String(cString: interface.ifa_name)
                if name == "en0" {
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

    public static func withArrayOfCStrings<R>(
        _ args: [String],
        _ body: ([UnsafeMutablePointer<CChar>?]) -> R
    ) -> R {
        var cStrings = args.map {
            strdup($0)
        }
        cStrings.append(nil)
        defer {
            cStrings.forEach {
                free($0)
            }
        }
        return body(cStrings)
    }

    public static func openUrl(_ url: String) {
        if let url = URL(string: url) {
            if #available(iOS 10, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }

    public static func getFileByName(_ array: [FileModel], file: FileModel) -> FileModel? {
        for afile in array {
            if afile.name == file.name {
                return afile
            }
        }
        return nil
    }
}

class Localize {
    static func get(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    static func get(key: String?) -> String? {
        guard let key = key else { return nil }
        return get(key)
    }

    static func getTermination(_ key: String, _ number: Int) -> String {
        let termination: [String] = [":single", ":plural", ":parent"]

        var value = number % 100
        var res: String

        if value > 10, value < 15 {
            res = get(key + termination[2])
        } else {
            value = value % 10

            if value == 0 { res = get(key + termination[2]) }
            else if value == 1 { res = get(key + termination[0]) }
            else if value > 1 { res = get(key + termination[1]) }
            else { res = get(key + termination[2]) }
        }

        return res
    }
}
