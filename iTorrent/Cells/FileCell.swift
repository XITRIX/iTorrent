//
//  FileCell.swift
//  iTorrent
//
//  Created by  XITRIX on 15.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class FileCell: ThemedUITableViewCell {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var size: UILabel!
	@IBOutlet weak var switcher: UISwitch!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet var progress: SegmentedProgressView!
    
    weak var actionDelegate : FileCellActionDelegate?
	var name : String!
	var index : Int!
    var adding = false
	weak var file : File!
	
	var hideUI : Bool = false
	
	@IBOutlet weak var titleConstraint: NSLayoutConstraint!
	
	override func themeUpdate() {
		super.themeUpdate()
		let theme = UserDefaults.standard.integer(forKey: UserDefaultsKeys.themeNum)
		title?.textColor = Themes.shared.theme[theme].mainText
		size?.textColor = Themes.shared.theme[theme].secondaryText
		
		let bgColorView = UIView()
		bgColorView.backgroundColor = Themes.shared.theme[theme].backgroundSecondary
		selectedBackgroundView = bgColorView
	}
	
    func update() {
		title.text = file?.name
        let progressValue = Float(file.downloaded) / Float(file.size)
        let percent = progressValue * 100
        size.text = adding ? Utils.getSizeText(size: file.size) : Utils.getSizeText(size: file.size) + " / " + Utils.getSizeText(size: file.downloaded) + " (" + String(format: "%.2f", percent) + "%)"
        progress?.setProgress(progressValue == 1 ? [1] : file.pieces.map{ CGFloat($0) })
        
		if (hideUI) {
			shareButton.isHidden = true
			switcher.isHidden = true
			titleConstraint.constant = 12
		} else {
			titleConstraint.constant = 74
			if (percent >= 100 && !adding) {
				shareButton.isHidden = false
				switcher.isHidden = true
			} else {
				shareButton.isHidden = true
				switcher.isHidden = false
			}
		}
		
		switch (file.isDownloading) {
		case 0:
			switcher.setOn(false, animated: true)
			switcher.onTintColor = nil
		case 1:
			switcher.setOn(true, animated: true)
			switcher.onTintColor = UIColor.gray
		case 2:
			switcher.setOn(true, animated: true)
			switcher.onTintColor = #colorLiteral(red: 1, green: 0.2980392157, blue: 0.168627451, alpha: 1)
		case 3:
			switcher.setOn(true, animated: true)
			switcher.onTintColor = UIColor.orange
		case 4:
			switcher.setOn(true, animated: true)
			switcher.onTintColor = nil
		default:
			break
		}
	}
	
	func canShare() -> Bool {
		let percent = Float(file.downloaded) / Float(file.size) * 100
		return percent >= 100 && !adding
	}
	
    @IBAction func switcherAction(_ sender: UISwitch) {
        if (actionDelegate != nil) {
            actionDelegate?.fileCellAction(sender, index: index)
        }
    }
	
    @IBAction func shareAction(_ sender: UIButton) {
		let controller = ThemedUIAlertController(title: nil, message: file.name, preferredStyle: .actionSheet)
		let share = UIAlertAction(title: NSLocalizedString("Share", comment: ""), style: .default) { _ in
			let path = NSURL(fileURLWithPath: Manager.rootFolder + "/" + self.file.path + "/" + self.file.name, isDirectory: false)
			let shareController = ThemedUIActivityViewController(activityItems: [path], applicationActivities: nil)
			if (shareController.popoverPresentationController != nil) {
				shareController.popoverPresentationController?.sourceView = sender
				shareController.popoverPresentationController?.sourceRect = sender.bounds
				shareController.popoverPresentationController?.permittedArrowDirections = .any
			}
			UIApplication.shared.keyWindow?.rootViewController?.present(shareController, animated: true)
		}
//		let delete = UIAlertAction(title: "Delete", style: .destructive) { _ in
//			let deleteController = ThemedUIAlertController(title: "Are you sure to delete?", message: self.file.fileName, preferredStyle: .actionSheet)
//			let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
//
//			}
//			let cancel = UIAlertAction(title: "Cancel", style: .cancel)
//
//			deleteController.addAction(deleteAction)
//			deleteController.addAction(cancel)
//
//			if (deleteController.popoverPresentationController != nil) {
//				deleteController.popoverPresentationController?.sourceView = sender
//				deleteController.popoverPresentationController?.sourceRect = sender.bounds
//				deleteController.popoverPresentationController?.permittedArrowDirections = .any
//			}
//
//			UIApplication.shared.keyWindow?.rootViewController?.present(deleteController, animated: true)
//		}
		let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)
		controller.addAction(share)
		//controller.addAction(delete)
		controller.addAction(cancel)
		
		if (controller.popoverPresentationController != nil) {
			controller.popoverPresentationController?.sourceView = sender
			controller.popoverPresentationController?.sourceRect = sender.bounds
			controller.popoverPresentationController?.permittedArrowDirections = .right
		}
		
		UIApplication.shared.keyWindow?.rootViewController?.present(controller, animated: true)
    }
}
