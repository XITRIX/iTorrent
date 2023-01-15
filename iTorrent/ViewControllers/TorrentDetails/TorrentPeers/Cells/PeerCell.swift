//
//  PeerCell.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 28.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

#if TRANSMISSION
import ITorrentTransmissionFramework
#else
import ITorrentFramework
#endif

import UIKit

class PeerCell: ThemedUITableViewCell {
    static let id = "PeerCell"
    static let nib = UINib(nibName: id, bundle: Bundle.main)

    @IBOutlet var ipText: UILabel!
    @IBOutlet var progress: UIProgressView!
    @IBOutlet var speed: UILabel!
    @IBOutlet var clientName: UILabel!

    func setModel(_ model: PeerModel) {
        let address: String
        if model.address.isIPv6 {
            address = "[\(model.address)]"
        } else {
            address = model.address
        }
        ipText.text = "tcp://\(address):\(model.port)"
        progress.progress = Float(model.progress) / 100
        speed.text = "↓ \(Utils.getSizeText(size: Int64(model.downSpeed)))/s | ↑ \(Utils.getSizeText(size: Int64(model.upSpeed)))/s"
        clientName.text = model.client
    }
}
