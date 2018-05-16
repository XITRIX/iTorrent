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
    @IBOutlet weak var share: UIButton!
    
    var action : (_ sender: UISwitch)->() = {_ in }
    
    @IBAction func switcherAction(_ sender: UISwitch) {
        action(sender)
    }
    @IBAction func shareAction(_ sender: UIButton) {
    }
}
