//
//  FilesBrowserController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 13/08/2019.
//  Copyright © 2019  XITRIX. All rights reserved.
//

import UIKit
import UniformTypeIdentifiers

@available(iOS 11.0, *)
class FilesBrowserController: UIDocumentPickerViewController {
    var onComplete: ((URL)->())?

    init(_ onComplete: @escaping (URL)->()) {
        super.init(forOpeningContentTypes: [UTType("com.bittorrent.torrent")!], asCopy: false)
        self.onComplete = onComplete
    }

    @available(*, unavailable)
    override init(forOpeningContentTypes contentTypes: [UTType], asCopy: Bool) {
        super.init(forOpeningContentTypes: contentTypes, asCopy: asCopy)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        allowsMultipleSelection = false
    }
}

@available(iOS 11.0, *)
extension FilesBrowserController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        dismiss(animated: true)
        onComplete?(url)
    }
}
