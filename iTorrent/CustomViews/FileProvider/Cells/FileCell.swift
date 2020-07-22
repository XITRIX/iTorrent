//
//  FileCell.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 31.03.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

class FileCell: ThemedUITableViewCell, UpdatableModel {
    static let id = "FileCell"
    static let nib = UINib(nibName: id, bundle: Bundle.main)
    
    @IBOutlet var title: UILabel!
    @IBOutlet var size: UILabel!
    @IBOutlet var shareButton: UIButton!
    @IBOutlet var prioritySwitch: UISwitch!
    @IBOutlet var progressBar: SegmentedProgressView!
    
    @IBOutlet var bottomConstraint: NSLayoutConstraint!
    
    weak var model: FileModel!
    
    func setModel(_ model: FileModel) {
        self.model = model
        updateModel()
    }
    
    func updateModel() {
        title.text = model.name
        if model.isPreview {
            size.text = "\(Utils.getSizeText(size: model.size))"
            shareButton.isHidden = true
            prioritySwitch.isHidden = false
            progressBar.isHidden = true
            bottomConstraint.constant = 6
        } else {
            let percent = Float(model.downloadedBytes) / Float(model.size) * 100
            size.text = "\(Utils.getSizeText(size: model.downloadedBytes)) / \(Utils.getSizeText(size: model.size)) (\(String(format: "%.2f", percent))%)"
            let downloaded = model.downloadedBytes == model.size
            shareButton.isHidden = !downloaded
            prioritySwitch.isHidden = downloaded
            progressBar.setProgress(downloaded ? [1] : model.pieces)
            progressBar.isHidden = false
            bottomConstraint.constant = 15
        }
        setSwitchColor()
    }
    
    func setSwitchColor() {
        switch model.priority {
        case .dontDownload:
            prioritySwitch.setOn(false, animated: true)
            prioritySwitch.onTintColor = nil
        case .lowPriority:
            prioritySwitch.setOn(true, animated: true)
            prioritySwitch.onTintColor = #colorLiteral(red: 1, green: 0.2980392157, blue: 0.168627451, alpha: 1)
        case .mediumPriority:
            prioritySwitch.setOn(true, animated: true)
            prioritySwitch.onTintColor = UIColor.orange
        case .normalPriority:
            prioritySwitch.setOn(true, animated: true)
            prioritySwitch.onTintColor = nil
        }
    }
    
    func onClick() {
        let downloaded = model.downloadedBytes == model.size
        if downloaded {
            share()
        } else {
            prioritySwitch.setOn(!prioritySwitch.isOn, animated: true)
            model.priority = prioritySwitch.isOn ? .normalPriority : .dontDownload
            setSwitchColor()
            
            if #available(iOS 10.0, *) {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        }
    }
    
    func share() {
        let controller = ThemedUIAlertController(title: nil, message: model.name, preferredStyle: .actionSheet)
                let share = UIAlertAction(title: NSLocalizedString("Share", comment: ""), style: .default) { _ in
                    let path = NSURL(fileURLWithPath: Core.rootFolder + "/" + self.model.path.path, isDirectory: false)
                    let shareController = ThemedUIActivityViewController(activityItems: [path], applicationActivities: nil)
                    if shareController.popoverPresentationController != nil {
                        shareController.popoverPresentationController?.sourceView = self.shareButton
                        shareController.popoverPresentationController?.sourceRect = self.shareButton.bounds
                        shareController.popoverPresentationController?.permittedArrowDirections = .any
                    }
                    Utils.topViewController?.present(shareController, animated: true)
                }
                //        let delete = UIAlertAction(title: "Delete", style: .destructive) { _ in
                //            let deleteController = ThemedUIAlertController(title: "Are you sure to delete?", message: self.file.fileName, preferredStyle: .actionSheet)
                //            let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
        //
                //            }
                //            let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        //
                //            deleteController.addAction(deleteAction)
                //            deleteController.addAction(cancel)
        //
                //            if (deleteController.popoverPresentationController != nil) {
                //                deleteController.popoverPresentationController?.sourceView = sender
                //                deleteController.popoverPresentationController?.sourceRect = sender.bounds
                //                deleteController.popoverPresentationController?.permittedArrowDirections = .any
                //            }
        //
                //            UIApplication.shared.keyWindow?.rootViewController?.present(deleteController, animated: true)
                //        }
                let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)
                controller.addAction(share)
                // controller.addAction(delete)
                controller.addAction(cancel)

                if controller.popoverPresentationController != nil {
                    controller.popoverPresentationController?.sourceView = self.shareButton
                    controller.popoverPresentationController?.sourceRect = self.shareButton.bounds
                    controller.popoverPresentationController?.permittedArrowDirections = .right
                }

                Utils.topViewController?.present(controller, animated: true)
    }
    
    @IBAction func shareAction(_ sender: Any) {
        share()
    }
}
