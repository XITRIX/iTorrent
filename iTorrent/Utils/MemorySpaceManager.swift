//
//  MemorySpaceManager.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 22.03.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import CoreServices
import UIKit

class MemorySpaceManager {
    enum FileErrors: Error {
        case BadEnumeration
        case BadResource
    }
    
    enum CategoryType: String {
        case video = "mime.video"
        case audio = "mime.audio"
        case image = "mime.image"
        case documents = "mime.documents"
        case other = "mime.other"
        case calculating = "mime.calculating"
        case free = "mime.free"
        
        var title: String {
            return Localize.get(rawValue)
        }
        
        var color: UIColor {
            switch self {
            case .video:
                return UIColor(hex: "#e43255")!
            case .audio:
                return UIColor(hex: "#59bbe5")!
            case .image:
                return UIColor(hex: "#e4bf0a")!
            case .documents:
                return UIColor(hex: "#aa50d8")!
            case .other, .calculating:
                return Themes.current.storageBarOther
            case .free:
                return Themes.current.storageBarEmpty
            }
        }
    }
    
    struct StorageSegment {
        var mime: String
        var size: Float
        var percentage: Float
    }
    
    struct StorageCategory {
        var category: CategoryType
        var segments: [StorageSegment]
        var size: Float {
            return segments.map { $0.size }.reduce(0, +)
        }
        
        var percentage: Float {
            return segments.map { $0.percentage }.reduce(0, +)
        }
    }
    
    public static let shared = MemorySpaceManager()
    
    var storage: [StorageSegment]
    var storageCategories: [StorageCategory]
    
    private init() {
        let freeSpace = Float(MemorySpaceManager.freeDiskSpaceInBytes)
        let usedSpace = Float(MemorySpaceManager.usedDiskSpaceByAppInBytes)
        
        let overallSpace = freeSpace + usedSpace
        
        let freeSpacePercentage = freeSpace / overallSpace
        let usedSpacePecentage = usedSpace / overallSpace
        
        storage = []
        storage.append(MemorySpaceManager.StorageSegment(mime: "calculating", size: usedSpace, percentage: usedSpacePecentage))
        storage.append(MemorySpaceManager.StorageSegment(mime: "free", size: freeSpace, percentage: freeSpacePercentage))
        
        storageCategories = []
        storageCategories.append(contentsOf: storage.map { StorageCategory(category: categoryFrom($0.mime), segments: [$0]) })
    }
    
    private var completionAction: (([StorageCategory]) -> ())?
    private var inProgress = false
    func calculateDetailedSections(completion: (([StorageCategory]) -> ())? = nil) {
        completionAction = completion
        
        if inProgress { return }
        inProgress = true
        
        DispatchQueue.global(qos: .background).async {
            let freeSpace = Float(MemorySpaceManager.freeDiskSpaceInBytes)
            
            let usedSpace = MemorySpaceManager.usedDiskSpaceByAppInBytesWithMime
            let mime = usedSpace.mime.sorted { $0 > $1 }
            
            let overallSpace = freeSpace + Float(usedSpace.overallSize)
            
            let freeSpacePercentage = freeSpace / overallSpace
            
            let storageBuff = mime.map { MemorySpaceManager.StorageSegment(mime: $0.key, size: Float($0.value), percentage: Float($0.value) / overallSpace) }
            
            self.storage.removeAll()
            self.storage.append(contentsOf: storageBuff)
            
            if let otherIdx = self.storage.firstIndex(where: { $0.mime == "other" }) {
                self.storage.append(self.storage.remove(at: otherIdx))
            }
            
            self.storage.append(MemorySpaceManager.StorageSegment(mime: "free", size: freeSpace, percentage: freeSpacePercentage))
            
            // Category
            self.storageCategories.removeAll()
            for segment in self.storage {
                let category = self.categoryFrom(segment.mime)
                if let elemIdx = self.self.storageCategories.firstIndex(where: { $0.category == category }) {
                    self.storageCategories[elemIdx].segments.append(segment)
                } else {
                    self.storageCategories.append(MemorySpaceManager.StorageCategory(category: category, segments: [segment]))
                }
            }
            //
            
            self.storageCategories = self.storageCategories.filter { $0.percentage > 0.005 }
            
            DispatchQueue.main.async {
                self.completionAction?(self.storageCategories)
                self.inProgress = false
            }
        }
    }
    
    func categoryFrom(_ mime: String) -> CategoryType {
        let category = String(mime.split(separator: "/")[0])
        
        switch category {
        case "video":
            return .video
        case "audio":
            return .audio
        case "image":
            return .image
        case "text", "font", "application", "model":
            return .documents
        case "free":
            return .free
        case "calculating":
            return .calculating
        default:
            return .other
        }
    }
    
    // MARK: Formatter MB only
    
    class func MBFormatter(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = ByteCountFormatter.Units.useMB
        formatter.countStyle = ByteCountFormatter.CountStyle.decimal
        formatter.includesUnit = false
        return formatter.string(fromByteCount: bytes) as String
    }
    
    // MARK: Get String Value
    
    class var totalDiskSpace: String {
        return ByteCountFormatter.string(fromByteCount: totalDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.file)
    }
    
    class var freeDiskSpace: String {
        return ByteCountFormatter.string(fromByteCount: freeDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.file)
    }
    
    class var usedDiskSpace: String {
        return ByteCountFormatter.string(fromByteCount: usedDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.file)
    }
    
    class var usedDiskSpaceByApp: String {
        return ByteCountFormatter.string(fromByteCount: usedDiskSpaceByAppInBytes, countStyle: ByteCountFormatter.CountStyle.file)
    }
    
    // MARK: Get raw value
    
    class var totalDiskSpaceInBytes: Int64 {
        do {
            let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String)
            let space = (systemAttributes[FileAttributeKey.systemSize] as? NSNumber)?.int64Value
            return space!
        } catch {
            return 0
        }
    }
    
    class var freeDiskSpaceInBytes: Int64 {
        do {
            let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String)
            let freeSpace = (systemAttributes[FileAttributeKey.systemFreeSize] as? NSNumber)?.int64Value
            return freeSpace!
        } catch {
            return 0
        }
    }
    
    class var usedDiskSpaceByAppInBytes: Int64 {
        do {
            return try findSizeInBytes(path: Core.rootFolder)
        } catch {
            return 0
        }
    }
    
    class var usedDiskSpaceByAppInBytesWithMime: (overallSize: Int64, mime: [String: Int64]) {
        do {
            return try findSizeInBytesWithMime(path: Core.rootFolder)
        } catch {
            return (0, [:])
        }
    }
    
    class var usedDiskSpaceInBytes: Int64 {
        let usedSpace = totalDiskSpaceInBytes - freeDiskSpaceInBytes
        return usedSpace
    }
    
    static func findSizeInBytes(path: String) throws -> Int64 {
        let fullPath = (path as NSString).expandingTildeInPath
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: fullPath)
        
        if fileAttributes[.type] as! FileAttributeType == FileAttributeType.typeRegular {
            return (fileAttributes[.size] as? NSNumber)!.int64Value
        }
        
        let url = URL(fileURLWithPath: fullPath)
        guard let directoryEnumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [URLResourceKey.fileSizeKey], options: [.skipsHiddenFiles]) else { throw FileErrors.BadEnumeration }
        
        var total: Int64 = 0
        
        for (index, object) in directoryEnumerator.enumerated() {
            guard let fileURL = object as? NSURL else { throw FileErrors.BadResource }
            
            var fileSizeResource: AnyObject?
            try fileURL.getResourceValue(&fileSizeResource, forKey: URLResourceKey.fileSizeKey)
            guard let fileSize = fileSizeResource as? NSNumber else { continue }
            total += fileSize.int64Value
            if index % 1000 == 0 {
                print(".", terminator: "")
            }
        }
        return total
    }
    
    static func findSizeInBytesWithMime(path: String) throws -> (overallSize: Int64, mime: [String: Int64]) {
        let fullPath = (path as NSString).expandingTildeInPath
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: fullPath)
        
        if fileAttributes[.type] as! FileAttributeType == FileAttributeType.typeRegular {
            return ((fileAttributes[.size] as? NSNumber)!.int64Value, [:])
        }
        
        let url = URL(fileURLWithPath: fullPath)
        guard let directoryEnumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [URLResourceKey.fileSizeKey], options: [.skipsHiddenFiles]) else { throw FileErrors.BadEnumeration }
        
        var total: Int64 = 0
        var mime: [String: Int64] = [:]
        
        for (index, object) in directoryEnumerator.enumerated() {
            guard let fileURL = object as? NSURL else { throw FileErrors.BadResource }
            
            let pathExtension = fileURL.pathExtension
            
            var fileSizeResource: AnyObject?
            try fileURL.getResourceValue(&fileSizeResource, forKey: URLResourceKey.fileSizeKey)
            guard let fileSize = fileSizeResource as? NSNumber else { continue }
            total += fileSize.int64Value
            if index % 1000 == 0 {
                print(".", terminator: "")
            }
            
            if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension! as NSString, nil)?.takeRetainedValue(),
                let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                mime[mimetype as String] = (mime[mimetype as String] ?? 0) + fileSize.int64Value
            } else {
                mime["other"] = (mime["other"] ?? 0) + fileSize.int64Value
            }
        }
        return (total, mime)
    }
}
