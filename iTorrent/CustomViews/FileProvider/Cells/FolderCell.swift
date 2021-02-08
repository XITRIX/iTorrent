//
//  FolderCell.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 31.03.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

#if TRANSMISSION
import ITorrentTransmissionFramework
#else
import ITorrentFramework
#endif
import UIKit

class FolderCell: ThemedUITableViewCell, UpdatableModel {
    static let id = "FolderCell"
    static let nib = UINib(nibName: id, bundle: Bundle.main)
    
    @IBOutlet var title: UILabel!
    @IBOutlet var size: UILabel!
    
    @IBOutlet var moreButton: UIButton!
    @IBOutlet var titleConstraint: NSLayoutConstraint!
    var titleConstraintValue: CGFloat {
        isEditing ? 16 : 34
    }
    
    weak var model: FolderModel!
    var moreAction: ((FolderModel) -> ())?
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        titleConstraint?.constant = titleConstraintValue
        UIView.animate(withDuration: animated ? 0.3 : 0) {
            self.moreButton.alpha = editing ? 0 : 1
            self.layoutIfNeeded()
        }
    }
    
    func setModel(_ model: FolderModel) {
        self.model = model
        updateModel()
        
        setEditing(isEditing, animated: false)
    }
    
    func updateModel() {
        title.text = model.name
        if model.isPreview {
            size.text = Utils.getSizeText(size: model.size)
        } else {
            let percent = Float(model.downloadedSize) / Float(model.size) * 100
            size.text = "\(Utils.getSizeText(size: model.downloadedSize)) / \(Utils.getSizeText(size: model.size)) (\(String(format: "%.2f", percent))%)"
        }
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
