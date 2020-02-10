//
//  ButtonCell.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 25/06/2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class ButtonCell: ThemedUITableViewCell, PreferenceCellProtocol {
    static let id = "ButtonCell"
    static let nib = UINib.init(nibName: id, bundle: nil)
    static let name = id

    @IBOutlet weak var title: ThemedUILabel!
    @IBOutlet weak var hintButton: UIButton!
    @IBOutlet weak var button: UIButton! {
        didSet {
            button.addTarget(self, action: #selector(executeAction), for: .touchUpInside)
        }
    }

    private var action: ((UIButton) -> ())?
    private var hintText: String?

    override func themeUpdate() {
        super.themeUpdate()
        let theme = Themes.current
        title?.textColor = theme.mainText
        button?.titleLabel?.textColor = theme.tintColor
    }

    func setModel(_ model: CellModelProtocol) {
        guard let model = model as? Model else {
            return
        }
        self.title.text = Localize.get(model.title)
        self.button.setTitle(Localize.get(model.buttonTitleFunc?() ?? model.buttonTitle), for: .normal)
        self.action = model.action
        
        hintText = model.hint
        hintButton.isHidden = hintText == nil
    }

    @objc private func executeAction() {
        action?(button)
    }
    
    @IBAction func hintButtonAction(_ sender: UIButton) {
        let vc = ThemedUIAlertController(title: "Hint", message: hintText, preferredStyle: .alert)
        vc.addAction(UIAlertAction(title: "OK", style: .cancel))
        UIApplication.shared.keyWindow?.rootViewController?.present(vc, animated: true)
    }
    
    struct Model: CellModelProtocol {
        var reuseCellIdentifier: String = id
        var title: String
        var buttonTitle: String = ""
        var hint: String? = nil
        var buttonTitleFunc: (() -> String)? = nil
        var hiddenCondition: (() -> Bool)? = nil
        var tapAction: (() -> ())? = nil
        var action: ((UIButton) -> ())
    }
}
