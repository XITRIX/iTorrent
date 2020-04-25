//
//  FolderCell.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 31.03.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

class FolderCell: ThemedUITableViewCell, UpdatableModel {
    static let id = "FolderCell"
    static let nib = UINib(nibName: id, bundle: Bundle.main)
    
    @IBOutlet var title: UILabel!
    @IBOutlet var size: UILabel!
    
    @IBOutlet var moreButton: UIButton!
    @IBOutlet var titleConstraint: NSLayoutConstraint!
    
    weak var model: FolderModel!
    var moreAction: ((FolderModel) -> ())?
    
    func update() {
        if isEditing {
            moreButton.isHidden = true
            titleConstraint?.constant = 13
        } else {
            moreButton.isHidden = false
            titleConstraint?.constant = 36
        }
    }
    
    func setModel(_ model: FolderModel) {
        self.model = model
        updateModel() 
    }
    
    func updateModel() {
        title.text = model.name
        size.text = Utils.getSizeText(size: model.size)
    }
    
    @IBAction func more(_ sender: UIButton) {
        let controller = ThemedUIAlertController(title: NSLocalizedString("Download content of folder", comment: ""), message: model.name, preferredStyle: .actionSheet)
        
        let download = UIAlertAction(title: NSLocalizedString("Download", comment: ""), style: .default) { _ in
            self.model.files.forEach { $0.priority = .normalPriority }
            self.moreAction?(self.model)
        }
        
        let notDownload = UIAlertAction(title: NSLocalizedString("Don't Download", comment: ""), style: .destructive) { _ in
            self.model.files.forEach { file in
                if file.size != 0, file.downloadedBytes == file.size {
                    file.priority = .normalPriority
                } else {
                    file.priority = .dontDownload
                }
                self.moreAction?(self.model)
            }
        }
        let cancel = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .cancel)
        
        controller.addAction(download)
        controller.addAction(notDownload)
        controller.addAction(cancel)
        
        if controller.popoverPresentationController != nil {
            controller.popoverPresentationController?.sourceView = sender
            controller.popoverPresentationController?.sourceRect = sender.bounds
            controller.popoverPresentationController?.permittedArrowDirections = .any
        }
        
        Utils.topViewController?.present(controller, animated: true)
    }
}
