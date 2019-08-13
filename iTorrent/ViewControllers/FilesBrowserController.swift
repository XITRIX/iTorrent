//
//  FilesBrowserController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 13/08/2019.
//  Copyright © 2019  XITRIX. All rights reserved.
//

import UIKit

@available(iOS 11.0, *)
class FilesBrowserController : UIDocumentPickerViewController {
    init() {
        super.init(documentTypes: ["com.bittorrent.torrent"], in: .open)
    }
    
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
extension FilesBrowserController : UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        dismiss(animated: true)
        Manager.addTorrentFromFile(url)
    }
}
