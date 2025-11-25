//
//  DocumentPickerViewController.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 25.11.2025.
//

import UIKit
import UniformTypeIdentifiers

class DocumentPickerViewController: UIDocumentPickerViewController, UIDocumentPickerDelegate {
    var completion: (([URL]) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        completion?(urls)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        completion?([])
    }
}

extension DocumentPickerViewController {
    static func pickFile(_ ofTypes: [UTType], from viewController: UIViewController) async -> URL? {
        let documentPicker = DocumentPickerViewController(forOpeningContentTypes: ofTypes, asCopy: true)
        documentPicker.allowsMultipleSelection = false
        documentPicker.shouldShowFileExtensions = true
        viewController.present(documentPicker, animated: true)
        let urls = await withCheckedContinuation { continuation in
            documentPicker.completion = { urls in
                continuation.resume(returning: urls)
            }
        }

        return urls.first
    }

    static func pickFiles(_ ofTypes: [UTType], from viewController: UIViewController) async -> URL? {
        let documentPicker = DocumentPickerViewController(forOpeningContentTypes: ofTypes, asCopy: true)
        documentPicker.allowsMultipleSelection = true
        documentPicker.shouldShowFileExtensions = true
        viewController.present(documentPicker, animated: true)
        let urls = await withCheckedContinuation { continuation in
            documentPicker.completion = { urls in
                continuation.resume(returning: urls)
            }
        }

        return urls.first
    }
}
