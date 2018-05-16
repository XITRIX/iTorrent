//
//  SwitchCell.swift
//  iTorrent
//
//  Created by  XITRIX on 15.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class SwitchCell: UITableViewCell {
    @IBOutlet weak var switcher: UISwitch!
    
    @IBOutlet weak var title: UILabel!
    @IBAction func valueChangedAction(_ sender: UISwitch) {
    }
}
