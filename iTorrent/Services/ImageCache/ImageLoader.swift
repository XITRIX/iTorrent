//
//  ImageLoader.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 24/04/2024.
//

import Combine
import Foundation
import UIKit.UIImage
import MvvmFoundation

public final class ImageLoader: Resolvable {
    public convenience init() {
        self.init(cache: ImageCache())
    }

    public init(cache: ImageCacheType) {
        self.cache = cache
    }

    public func loadImage(from url: URL, forceUpdate: Bool = false) async -> UIImage? {
        if !forceUpdate, let image = cache[url] {
            return image
        }

        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let image = UIImage(data: data)
        else { return nil }

        cache[url] = image
        return image
    }

    private let cache: ImageCacheType
    private lazy var backgroundQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 5
        return queue
    }()
}
