//
//  FileCell.swift
//  iTorrent
//
//  Created by  XITRIX on 15.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class FileCell: UITableViewCell {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var size: UILabel!
    @IBOutlet weak var switcher: UISwitch!
    @IBOutlet weak var shareButton: UIButton!
    
    var action : (_ sender: UISwitch)->() = {_ in }
	var name : String!
	var indexPath : IndexPath!
	var file : FileInfo!
	
	func update() {
		title.text = file?.fileName
		let percent = Float(file.fileDownloaded) / Float(file.fileSize) * 100
		size.text = Utils.getSizeText(size: file.fileSize) + " / " + Utils.getSizeText(size: file.fileDownloaded) + " (" + String(format: "%.2f", percent) + "%)"
		
		if (percent >= 100) {
			shareButton.isHidden = false
			switcher.isHidden = true
		} else {
			shareButton.isHidden = true
			switcher.isHidden = false
		}
	}
    
    @IBAction func switcherAction(_ sender: UISwitch) {
        action(sender)
    }
    @IBAction func shareAction(_ sender: UIButton) {
		let controller = UIAlertController(title: file.fileName, message: nil, preferredStyle: .actionSheet)
		let share = UIAlertAction(title: "Share", style: .default) { _ in
			let path = NSURL(fileURLWithPath: Manager.rootFolder + "/" + self.file.filePath, isDirectory: false)
			let shareController = UIActivityViewController(activityItems: [path], applicationActivities: nil)
			if (shareController.popoverPresentationController != nil) {
				shareController.popoverPresentationController?.sourceView = sender;
				shareController.popoverPresentationController?.sourceRect = sender.bounds;
				shareController.popoverPresentationController?.permittedArrowDirections = .any;
			}
			UIApplication.shared.keyWindow?.rootViewController?.present(shareController, animated: true)
		}
		let cancel = UIAlertAction(title: "Cancel", style: .cancel)
		controller.addAction(share)
		controller.addAction(cancel)
		UIApplication.shared.keyWindow?.rootViewController?.present(controller, animated: true)
    }
}
