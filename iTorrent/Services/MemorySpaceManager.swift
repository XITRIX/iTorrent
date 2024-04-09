//
//  MemorySpaceManager.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 22.03.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import CoreServices
import UIKit
import UniformTypeIdentifiers

public final class MemorySpaceManager: @unchecked Sendable {
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
            String(localized: .init(rawValue))
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
                return .systemGray
            case .free:
                return .systemFill
            }
        }
    }

    struct StorageSegment {
        var mime: String
        var size: Float
        var percentage: Float
    }

    public struct StorageCategory: Sendable {
        var category: CategoryType
        var segments: [StorageSegment]
        var size: Float {
            segments.map {
                $0.size
            }.reduce(0, +)
        }

        var percentage: Float {
            segments.map {
                $0.percentage
            }.reduce(0, +)
        }
    }

    public static let shared = MemorySpaceManager()

    @Published public private(set) var storageCategories: [StorageCategory]

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

        Task { await update() }
    }

    func update() async {
        guard !isUpdating else { return }
        isUpdating = true
        await calculateDetailedSections()
        isUpdating = false
    }

    private var isUpdating = false
    private var storage: [StorageSegment]
}

public extension MemorySpaceManager {
    // MARK: Get String Value

    static var totalDiskSpace: String {
        ByteCountFormatter.string(fromByteCount: totalDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.file)
    }

    static var freeDiskSpace: String {
        ByteCountFormatter.string(fromByteCount: freeDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.file)
    }

    static var usedDiskSpace: String {
        ByteCountFormatter.string(fromByteCount: usedDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.file)
    }

    static var usedDiskSpaceByApp: String {
        ByteCountFormatter.string(fromByteCount: usedDiskSpaceByAppInBytes,
                                  countStyle: ByteCountFormatter.CountStyle.file)
    }
}

private extension MemorySpaceManager {
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

    func calculateDetailedSections() async {
        let freeSpace = Float(MemorySpaceManager.freeDiskSpaceInBytes)

        let usedSpace = MemorySpaceManager.usedDiskSpaceByAppInBytesWithMime
        let mime = usedSpace.mime.sorted { $0 > $1 }

        let overallSpace = freeSpace + Float(usedSpace.overallSize)

        let freeSpacePercentage = freeSpace / overallSpace

        let storageBuff = mime.map { MemorySpaceManager.StorageSegment(mime: $0.key, size: Float($0.value), percentage: Float($0.value) / overallSpace) }

        storage.removeAll()
        storage.append(contentsOf: storageBuff)

        if let otherIdx = storage.firstIndex(where: { $0.mime == "other" }) {
            storage.append(storage.remove(at: otherIdx))
        }

        storage.append(MemorySpaceManager.StorageSegment(mime: "free", size: freeSpace, percentage: freeSpacePercentage))

        // Category
        var localStorageCategories: [StorageCategory] = []
        for segment in storage {
            let category = categoryFrom(segment.mime)
            if let elemIdx = localStorageCategories.firstIndex(where: { $0.category == category }) {
                localStorageCategories[elemIdx].segments.append(segment)
            } else {
                localStorageCategories.append(MemorySpaceManager.StorageCategory(category: category, segments: [segment]))
            }
        }
        //

        await MainActor.run { [localStorageCategories] in
            storageCategories = localStorageCategories.filter { $0.percentage > 0.005 }
        }
    }

    // MARK: Formatter MB only

    static func MBFormatter(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = ByteCountFormatter.Units.useMB
        formatter.countStyle = ByteCountFormatter.CountStyle.decimal
        formatter.includesUnit = false
        return formatter.string(fromByteCount: bytes) as String
    }

    // MARK: Get raw value

    static var totalDiskSpaceInBytes: Int64 {
        do {
            let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String)
            let space = (systemAttributes[FileAttributeKey.systemSize] as? NSNumber)?.int64Value
            return space!
        } catch {
            return 0
        }
    }

    static var freeDiskSpaceInBytes: Int64 {
        do {
            let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String)
            let freeSpace = (systemAttributes[FileAttributeKey.systemFreeSize] as? NSNumber)?.int64Value
            return freeSpace!
        } catch {
            return 0
        }
    }

    static var usedDiskSpaceByAppInBytes: Int64 {
        do {
            return try findSizeInBytes(path: TorrentService.downloadPath.path())
        } catch {
            return 0
        }
    }

    static var usedDiskSpaceByAppInBytesWithMime: (overallSize: Int64, mime: [String: Int64]) {
        do {
            return try findSizeInBytesWithMime(path: TorrentService.downloadPath.path())
        } catch {
            return (0, [:])
        }
    }

    static var usedDiskSpaceInBytes: Int64 {
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

            if let uti = UTType(tag: pathExtension!, tagClass: UTTagClass.filenameExtension, conformingTo: nil),
               let mimetype = uti.preferredMIMEType
            {
                mime[mimetype] = (mime[mimetype] ?? 0) + fileSize.int64Value
            } else {
                mime["other"] = (mime["other"] ?? 0) + fileSize.int64Value
            }
        }
        return (total, mime)
    }
}
