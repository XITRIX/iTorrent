//
//  UIImage+File.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 04/11/2023.
//

import UIKit
import QuickLookThumbnailing

extension UIImage {
    public enum FileIconSize {
        case smallest
        case largest
    }

    @MainActor 
    public class func icon(forFileURL fileURL: URL, preferredSize: FileIconSize = .smallest) -> UIImage {
        let myInteractionController = UIDocumentInteractionController(url: fileURL)
        let allIcons = myInteractionController.icons

        // allIcons is guaranteed to have at least one image (fails on Catalyst)
        switch preferredSize {
        case .smallest: return allIcons.first ?? UIImage()
        case .largest: return allIcons.last ?? UIImage()
        }
    }

    @MainActor
    public class func icon(forFileURL fileURL: URL, size: CGSize, scale: CGFloat) async throws -> UIImage {
        let request = QLThumbnailGenerator.Request(fileAt: fileURL, size: size, scale: scale, representationTypes: .icon)
        request.iconMode = false

        let representation = try await QLThumbnailGenerator.shared.generateBestRepresentation(for: request)
        return representation.uiImage
    }
}

extension QLThumbnailGenerator {
    func generateRepresentations(for request: QLThumbnailGenerator.Request) async throws -> QLThumbnailRepresentation {
        try await withCheckedThrowingContinuation { continuation in
            generateRepresentations(for: request) { thumbnail, _, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                if let thumbnail {
                    continuation.resume(returning: thumbnail)
                }
            }
        }
    }
}
