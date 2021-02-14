//
//  RssFeedCell.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 06.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

class RssChannelCell: ThemedUITableViewCell {
    static let id = "RssChannelCell"
    static let nib = UINib(nibName: id, bundle: Bundle.main)

    @IBOutlet var title: ThemedUILabel!
    @IBOutlet var imageFav: UIImageView!
    @IBOutlet var descriptionText: ThemedUILabel!
    @IBOutlet var updatesLabel: UILabel!
    @IBOutlet var setupButton: UIButton!

    @IBOutlet var stackTrailing: NSLayoutConstraint!

    weak var parent: RssFeedController?
    weak var model: RssModel!

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        stackTrailing.constant = editing ? 37 : 8
        UIView.animate(withDuration: animated ? 0.3 : 0) {
            self.setupButton.alpha = editing ? 1 : 0
            self.updatesLabel.superview?.alpha = editing || self.model.updatesCount == 0 ? 0 : 1
            self.layoutIfNeeded()
        }
    }

    func setModel(_ model: RssModel) {
        self.model = model
        updateCellView()
        setEditing(isEditing, animated: false)
    }

    func updateCellView() {
        title.text = model.displayTitle
        descriptionText.text = model.displayDescription
        imageFav.image = UIImage(named: "Rss")
        imageFav.load(url: model.linkImage)

        let updatesCount = model.updatesCount
        updatesLabel.superview?.alpha = isEditing || updatesCount == 0 ? 0 : 1
        updatesLabel.text = "\(updatesCount)"
    }

    var vc: RssChannelSetupController!
    @IBAction func setupAction(_ sender: UIButton) {
        vc = Utils.instantiate("RssChannelSetup")
        vc.model = model
        parent?.channelSetupView?.dismiss(animationOnly: true)
      parent?.channelSetupView = PopupView(contentView: vc.view, contentHeight: 198, dismissAction:  {
        if let editing = self.parent?.isEditing {
          self.parent?.channelSetupView = nil
          self.parent?.navigationController?.setToolbarHidden(!editing, animated: true)
        }
      })
        parent?.navigationController?.setToolbarHidden(true, animated: true)
        parent?.channelSetupView?.show(parent!)
    }
}
