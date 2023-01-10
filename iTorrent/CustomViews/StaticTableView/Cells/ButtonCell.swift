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
    static let nib = UINib(nibName: id, bundle: nil)
    static let name = id

    @IBOutlet var title: ThemedUILabel!
    @IBOutlet var hintButton: UIButton!
    @IBOutlet var button: UIButton! {
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
        selectedBackgroundView = nil
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            executeAction()
            setSelected(false, animated: true)
        }
    }

    func setModel(_ model: CellModelProtocol) {
        guard let model = model as? Model else {
            return
        }
        title.text = Localize.get(model.title)
        title.font = model.bold ? title.font.bold() : title.font.normal()
        UIView.performWithoutAnimation {
            button.setTitle(Localize.get(model.buttonTitleFunc?() ?? model.buttonTitle), for: .normal)
            button.layoutIfNeeded()
        }
        action = model.action

        hintText = model.hint
        hintButton.isHiddenInStackView = hintText == nil
    }

    @objc private func executeAction() {
        action?(button)
    }

    @IBAction func hintButtonAction(_ sender: UIButton) {
        Dialog.show(title: "Hint", message: hintText, closeText: "OK")
    }

    struct Model: CellModelProtocol {
        var reuseCellIdentifier: String = id
        var title: String
        var bold: Bool = false
        var buttonTitle: String = ""
        var hint: String?
        var buttonTitleFunc: (() -> String)?
        var hiddenCondition: (() -> Bool)?
        var tapAction: (() -> ())?
        var longPressAction: (() -> ())?
        var action: (UIButton) -> ()
    }
}
