//
//  PeerCell.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 28.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

class PeerCell: ThemedUITableViewCell {
    static let id = "PeerCell"
    static let nib = UINib(nibName: id, bundle: Bundle.main)

    @IBOutlet var ipText: UILabel!
    @IBOutlet var progress: UIProgressView!
    
    func setModel(_ model: PeerModel) {
        ipText.text = "\(model.address):\(model.port)"
        progress.progress = Float(model.progress) / 100
    }
}
