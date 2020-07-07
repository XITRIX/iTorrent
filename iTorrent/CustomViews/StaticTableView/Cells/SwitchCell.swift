//
//  SwitchCell.swift
//  iTorrent
//
//  Created by  XITRIX on 15.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation
import UIKit

class SwitchCell: ThemedUITableViewCell, PreferenceCellProtocol {
    static let id = "SwitchCell"
    static let nib = UINib(nibName: id, bundle: nil)
    static let name = id

    @IBOutlet var title: UILabel!
    @IBOutlet var hintButton: UIButton!
    @IBOutlet var switcher: UISwitch! {
        didSet {
            switcher.addTarget(self, action: #selector(executeAction), for: .valueChanged)
        }
    }

    private var action: ((UISwitch) -> ())?
    private var hintText: String?

    override func themeUpdate() {
        super.themeUpdate()
        let theme = Themes.current
        title.textColor = theme.mainText
    }

    override func prepareForReuse() {
        switcher.onTintColor = nil
    }

    func setModel(_ model: CellModelProtocol) {
        if let model = model as? Model {
            setModel(model)
        }
//        else if let model = model as? ModelProperty {
//            setModel(model)
//        }
        else {
            return
        }
    }

    func setModel(_ model: Model) {
        title.text = Localize.get(model.title)
        action = model.action

        switcher.onTintColor = model.switchColor
        switcher.isEnabled = !(model.disableCondition?() ?? false)
        switcher.setOn(model.defaultValue(), animated: false)

        hintText = model.hint
        hintButton.isHiddenInStackView = hintText == nil
    }

//    func setModel(_ model: ModelProperty) {
//        title.text = Localize.get(model.title)
//        action = { switcher in
//            model.property.wrappedValue = switcher.isOn
//            model.action?(switcher)
//        }
//        switcher.onTintColor = model.switchColor
//        switcher.isEnabled = !(model.disableCondition?() ?? false)
//        switcher.setOn(model.property.wrappedValue, animated: false)
//
//        hintText = model.hint
//        hintButton.isHiddenInStackView = hintText == nil
//    }

    @objc private func executeAction() {
        action?(switcher)
    }

    @IBAction func hintButtonAction(_ sender: UIButton) {
        Dialog.show(title: "Hint", message: hintText, closeText: "OK")
    }

    struct Model: CellModelProtocol {
        var reuseCellIdentifier: String = id
        var title: String
        var defaultValue: () -> Bool
        var hint: String?
        var switchColor: UIColor?
        var hiddenCondition: (() -> Bool)?
        var disableCondition: (() -> Bool)?
        var tapAction: (() -> ())?
        var action: (UISwitch) -> ()
    }

//    struct ModelProperty: CellModelProtocol {
//        var reuseCellIdentifier: String = id
//        var title: String
//        var property: PreferenceItem<Bool>
//        var hint: String?
//        var switchColor: UIColor?
//        var hiddenCondition: (() -> Bool)?
//        var disableCondition: (() -> Bool)?
//        var tapAction: (() -> ())?
//        var action: ((UISwitch) -> ())?
//    }
}
