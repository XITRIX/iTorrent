//
//  UIImage+File.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 04/11/2023.
//

import UIKit

extension UIImage {
    public enum FileIconSize {
        case smallest
        case largest
    }

    public class func icon(forFileURL fileURL: URL, preferredSize: FileIconSize = .smallest) -> UIImage {
        let myInteractionController = UIDocumentInteractionController(url: fileURL)
        let allIcons = myInteractionController.icons

        // allIcons is guaranteed to have at least one image (fails on Catalyst)
        switch preferredSize {
        case .smallest: return allIcons.first ?? UIImage()
        case .largest: return allIcons.last ?? UIImage()
        }
    }
}
