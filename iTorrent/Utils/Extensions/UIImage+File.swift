//
//  UIImage+File.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 04/11/2023.
//

import QuickLookThumbnailing
import UIKit

public extension UIImage {
    private enum IconStorage {
        @MainActor
        static var storage: [String: UIImage] = [:]
    }

//    enum FileIconSize {
//        case smallest
//        case largest
//    }

//    @MainActor
//    public class func icon(forFileURL fileURL: URL, preferredSize: FileIconSize = .largest) -> UIImage {
//        let myInteractionController = UIDocumentInteractionController(url: fileURL)
//        myInteractionController.presentOptionsMenu(from: .init(x: 100, y: 100, width: 40, height: 40), in: UIApplication.shared.keySceneWindow!, animated: true)
//
    ////        UIApplication.shared.keySceneWindow?.rootViewController?.present(myInteractionController, animated: true)
//
//        print("\(fileURL.path)")
//        print("UTI: \(myInteractionController.uti ?? "none")")
//        let allIcons = myInteractionController.icons
//
//        // allIcons is guaranteed to have at least one image (fails on Catalyst)
//        switch preferredSize {
//        case .smallest: return allIcons.first ?? UIImage()
//        case .largest: return allIcons.last ?? UIImage()
//        }
//    }

    @MainActor
    class func icon(forFileURL fileURL: URL, size: CGFloat = 44, scale: CGFloat? = nil, forcePlaceholder: Bool = false) -> UIImage {
        let scale = scale ?? UITraitCollection.current.displayScale
        let key = "\(fileURL.pathExtension)-\(size * scale)"
        if let icon = IconStorage.storage[key] {
            return icon
        }

        let uti = UTType(tag: fileURL.pathExtension, tagClass: UTTagClass.filenameExtension, conformingTo: nil)
        let mimetype = uti?.preferredMIMEType

        let category = mimetype.map { String($0.split(separator: "/")[0]) }

        let mod = (size * scale) / 512
        let size = CGSize(width: size * scale, height: size * scale)

        let renderer = UIGraphicsImageRenderer(size: size)
        let result = renderer.image { _ in

            UIImage(resource: .thumbnailBackground).draw(in: CGRect(origin: .zero, size: size))

            if fileURL.pathExtension.count < 8 {
                let textRect = CGRect(x: 0, y: 396 * mod, width: size.width, height: 61 * mod) // Position and size of text area
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .center

                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 51 * mod, weight: .regular),
                    .foregroundColor: UIColor(hex: "#BEBEC0") ?? .black,
                    .paragraphStyle: paragraphStyle
                ]
                (fileURL.pathExtension.uppercased() as NSString).draw(in: textRect, withAttributes: attributes)
            }

            print("Type: \(mimetype ?? "None") | Category: \(category ?? "None")")
            switch category {
            case "video":
                UIImage(resource: .thumbnailVideo).draw(in: CGRect(origin: .zero, size: size))
            case "audio":
                UIImage(resource: .thumbnailAudio).draw(in: CGRect(origin: .zero, size: size))
            case "image":
                UIImage(resource: .thumbnailPhoto).draw(in: CGRect(origin: .zero, size: size))
            case "text", "font", "model":
                UIImage(resource: .thumbnailDocument).draw(in: CGRect(origin: .zero, size: size))
            default:
                let ext = fileURL.pathExtension.lowercased()
                if ext == "7z" || ext == "rar" || ext == "zip" {
                    UIImage(resource: .thumbnailArchive).draw(in: CGRect(origin: .zero, size: size))
                }
                if ext == "torrent" {
                    UIImage(resource: .thumbnailTorrent).draw(in: CGRect(origin: .zero, size: size))
                }
            }
            UIImage(resource: .thumbnailForeground).draw(in: CGRect(origin: .zero, size: size))
        }
        IconStorage.storage[key] = result
        return result
    }

    @MainActor
    class func icon2(forFileURL fileURL: URL, size: CGSize = .init(width: 512, height: 512), scale: CGFloat = 3, forcePlaceholder: Bool = false) async throws -> UIImage {
        var fileURL = fileURL

        let exists = forcePlaceholder || FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false))
        if !exists {
            print("NOT EXISTS: \(fileURL.path(percentEncoded: false))")
            fileURL = FileManager.default.temporaryDirectory.appending(path: "iconFile-\(fileURL.lastPathComponent).\(fileURL.pathExtension)")
            FileManager.default.createFile(atPath: fileURL.path(percentEncoded: false), contents: Data())
        }

        let request = QLThumbnailGenerator.Request(fileAt: fileURL, size: size, scale: scale, representationTypes: .icon)
        request.iconMode = false

        let representation = try await QLThumbnailGenerator.shared.generateBestRepresentation(for: request)

        if !exists {
            try? FileManager.default.removeItem(at: fileURL)
        }

        if let data = representation.uiImage.pngData() {
            let path = TorrentService.downloadPath.appending(path: "images/\(fileURL.pathExtension).png")
            FileManager.default.createFile(atPath: path.path(percentEncoded: false), contents: data)
        }
        return representation.uiImage
    }
}

// extension QLThumbnailGenerator {
//    func generateRepresentations(for request: QLThumbnailGenerator.Request) async throws -> QLThumbnailRepresentation {
//        try await withCheckedThrowingContinuation { continuation in
//            generateRepresentations(for: request) { thumbnail, _, error in
//                if let error {
//                    continuation.resume(throwing: error)
//                    return
//                }
//                if let thumbnail {
//                    continuation.resume(returning: thumbnail)
//                }
//            }
//        }
//    }
// }
