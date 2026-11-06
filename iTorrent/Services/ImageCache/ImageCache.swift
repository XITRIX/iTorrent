//
//  ImageCache.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 24/04/2024.
//

import Foundation
import UIKit.UIImage

/// A cache whose operations may be called concurrently from any executor.
public protocol ImageCacheType: AnyObject, Sendable {
    // Returns the image associated with a given url
    func image(for url: URL) -> UIImage?
    // Inserts the image of the specified url in the cache
    func insertImage(_ image: UIImage?, for url: URL)
    // Removes the image of the specified url in the cache
    func removeImage(for url: URL)
    // Removes all images from the cache
    func removeAllImages()
    // Accesses the value associated with the given key for reading and writing
    subscript(_ url: URL) -> UIImage? { get set }
}

// Both caches are initialized before sharing the instance. The lock serializes
// all access to the two levels, including promotions and removals.
public final class ImageCache: ImageCacheType, @unchecked Sendable {
    // 1st level cache, that contains encoded images
    private let imageCache: NSCache<NSURL, UIImage>

    // 2nd level cache, that contains decoded images
    private let decodedImageCache: NSCache<NSURL, UIImage>

    private let lock = NSLock()

    public struct Config: Sendable {
        public let countLimit: Int
        public let memoryLimit: Int

        public static let defaultConfig = Config(countLimit: 100, memoryLimit: 1024 * 1024 * 100) // 100 MB
    }

    public init(config: Config = Config.defaultConfig) {
        imageCache = NSCache<NSURL, UIImage>()
        imageCache.countLimit = config.countLimit
        decodedImageCache = NSCache<NSURL, UIImage>()
        decodedImageCache.totalCostLimit = config.memoryLimit
    }

    public func image(for url: URL) -> UIImage? {
        lock.lock(); defer { lock.unlock() }
        // the best case scenario -> there is a decoded image in memory
        if let decodedImage = decodedImageCache.object(forKey: url as NSURL) {
            return decodedImage
        }
        // search for image data
        if let image = imageCache.object(forKey: url as NSURL) {
            let decodedImage = image.decodedImage()
            decodedImageCache.setObject(decodedImage, forKey: url as NSURL, cost: decodedImage.diskSize)
            return decodedImage
        }
        return nil
    }

    public func insertImage(_ image: UIImage?, for url: URL) {
        guard let image = image else { return removeImage(for: url) }
        let decompressedImage = image.decodedImage()

        lock.lock(); defer { lock.unlock() }
        imageCache.setObject(image, forKey: url as NSURL, cost: 1)
        decodedImageCache.setObject(decompressedImage, forKey: url as NSURL, cost: decompressedImage.diskSize)
    }

    public func removeImage(for url: URL) {
        lock.lock(); defer { lock.unlock() }
        imageCache.removeObject(forKey: url as NSURL)
        decodedImageCache.removeObject(forKey: url as NSURL)
    }

    public func removeAllImages() {
        lock.lock(); defer { lock.unlock() }
        imageCache.removeAllObjects()
        decodedImageCache.removeAllObjects()
    }

    public subscript(_ key: URL) -> UIImage? {
        get {
            image(for: key)
        }
        set {
            insertImage(newValue, for: key)
        }
    }
}

private extension UIImage {
    func decodedImage() -> UIImage {
        guard let cgImage = cgImage else { return self }
        let size = CGSize(width: cgImage.width, height: cgImage.height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo)
        context?.draw(cgImage, in: CGRect(origin: .zero, size: size))
        guard let decodedImage = context?.makeImage() else { return self }
        return UIImage(cgImage: decodedImage, scale: scale, orientation: imageOrientation)
    }

    // Rough estimation of how much memory image uses in bytes
    var diskSize: Int {
        guard let cgImage = cgImage else { return 0 }
        return cgImage.bytesPerRow * cgImage.height
    }
}
