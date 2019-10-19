//
//  SegueCell.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 02.09.2019.
//  Copyright © 2019  XITRIX. All rights reserved.
//

import UIKit

class SegueCell : ThemedUITableViewCell, PreferenceCellProtocol {
    static let id = "SegueCell"
    static let nib = UINib.init(nibName: id, bundle: Bundle.main)
    static let name = id
    
    @IBOutlet var title: ThemedUILabel!
    
    func setModel(_ model: CellModelProtocol) {
        guard let model = model as? Model else { return }
        title?.text = Localize.get(model.title)
    }
    
    struct Model : CellModelProtocol {
        var reuseCellIdentifier: String = id
        var title: String
        var segueViewId: String? = nil
        var hiddenCondition: (() -> Bool)? = nil
        var tapAction : (()->())? = nil
        
        init(title: String, tapAction: @escaping ()->()) {
            self.title = title
            self.tapAction = tapAction
        }
        
        init(_ vc: UIViewController, title: String, segueViewId: String, isModal: Bool = false) {
            self.title = title
            self.segueViewId = segueViewId
            
            tapAction = {
                if let tvc = vc.storyboard?.instantiateViewController(withIdentifier: segueViewId) {
                    if isModal {
                        vc.present(tvc, animated: true)
                    } else {
                        vc.show(tvc, sender: vc)
                    }
                }
            }
        }
    }
}
