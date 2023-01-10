//
//  Utils.swift
//  iTorrent
//
//  Created by  XITRIX on 15.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation

//var ObserverKey: UInt8 = 0
//public extension NSObject {
//    static func oldOSPatch() {
//        let originalSelector = #selector(NSObject.addObserver(_:forKeyPath:options:context:))
//        let swizzledSelector = #selector(NSObject.swizzled_addObserver(observer:forKeyPath:options:context:))
//
//        let originalMethod = class_getInstanceMethod(self, originalSelector)
//        let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
//        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
//            // switch implementation..
//            method_exchangeImplementations(originalMethod, swizzledMethod)
//        }
//
//        let doriginalSelector = #selector("dealloc")
//        let dswizzledSelector = #selector(NSObject.swizzled_dealloc)
//
//        let doriginalMethod = class_getInstanceMethod(self, doriginalSelector)
//        let dswizzledMethod = class_getInstanceMethod(self, dswizzledSelector)
//        if let doriginalMethod = doriginalMethod, let dswizzledMethod = dswizzledMethod {
//            // switch implementation..
//            method_exchangeImplementations(doriginalMethod, dswizzledMethod)
//        }
//    }
//
//    @objc func swizzled_addObserver(observer: NSObject, forKeyPath: String, options: NSKeyValueObservingOptions, context: UnsafeMutableRawPointer?) {
//        var observerSet = objc_getAssociatedObject(self, &ObserverKey) as? NSMutableSet
//        if observerSet == nil {
//            observerSet = NSMutableSet()
//            objc_setAssociatedObject(self, &ObserverKey, observerSet, .OBJC_ASSOCIATION_RETAIN)
//        }
//        // store all observer info into a set.
//        observerSet?.add([observer, forKeyPath])
//
//        swizzled_addObserver(observer: observer, forKeyPath: forKeyPath, options: options, context: context) // this will call the origin impl
//    }
//
//    @objc func swizzled_dealloc() {
//        let observerSet = objc_getAssociatedObject(self, &ObserverKey) as? NSMutableSet
//        objc_setAssociatedObject(self, &ObserverKey, nil, .OBJC_ASSOCIATION_RETAIN)
//        if let observerSet = observerSet {
//            for arr in observerSet {
//                if let arr = arr as? NSArray,
//                    arr.count == 2,
//                    let obj = arr[0] as? NSObject,
//                    let path = arr[1] as? String
//                {
//                    // remove all observers before self is deallocated.
//                    removeObserver(obj, forKeyPath: path)
//                }
//            }
//        }
//    }
//}

class Utils {

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
