//
//  FolderCellActionDelegate.swift
//  iTorrent
//
//  Created by  XITRIX on 19.06.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

protocol FolderCellActionDelegate: class {
    func folderCellAction(_ key: String, sender: UIButton)
}
