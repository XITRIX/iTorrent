//
//  SegueCell.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 02.09.2019.
//  Copyright © 2019  XITRIX. All rights reserved.
//

import UIKit

class SegueCell : ThemedUITableViewCell, PreferenceCellProtocol {
    @IBOutlet var title: ThemedUILabel!
    
    func setModel(_ model: CellModelProtocol) {
        guard let model = model as? Model else { return }
        title?.text = Localize.get(model.title) 
    }
    
    struct Model : CellModelProtocol {
        var reuseCellIdentifier: String = "SegueCell"
        var title: String
        var hiddenCondition: (() -> Bool)? = nil
        var tapAction : (()->())? = nil
    }
}
