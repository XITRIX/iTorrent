//
//  FolderCell.swift
//  iTorrent
//
//  Created by  XITRIX on 18.06.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class FolderCell : UITableViewCell {
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var size: UILabel!
    
    weak var actionDelegate : FolderCellActionDelegate?
    
    @IBAction func more(_ sender: UIButton) {
        if (actionDelegate != nil) {
            actionDelegate?.folderCellAction(title.text!, sender: sender)
        }
    }
    
}
