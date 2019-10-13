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
    @IBOutlet weak var switcher: UISwitch! {
        didSet {
            switcher.addTarget(self, action: #selector(executeAction), for: .valueChanged)
        }
    }
    
    @IBOutlet weak var title: UILabel!
    
    var action: ((UISwitch)->())?
	
	override func themeUpdate() {
		super.themeUpdate()
        let theme = Themes.current
		title?.textColor = theme.mainText
	}
    
    override func prepareForReuse() {
        switcher.onTintColor = nil
    }
    
    func setModel(_ model: CellModelProtocol) {
        if let model = model as? Model {
            setModel(model)
        }
        else if let model = model as? ModelProperty {
            setModel(model)
        }
        else { return }
    }
    
    func setModel(_ model: Model) {
        self.title.text = Localize.get(model.title) 
        self.action = model.action
        
        switcher.onTintColor = model.switchColor
        switcher.isEnabled = !(model.disableCondition?() ?? false)
        switcher.setOn(model.defaultValue(), animated: false)
    }
    
    func setModel(_ model: ModelProperty) {
        self.title.text = Localize.get(model.title)
        self.action = { switcher in
            model.property.value = switcher.isOn
            model.action?(switcher)
        }
        switcher.onTintColor = model.switchColor
        switcher.isEnabled = !(model.disableCondition?() ?? false)
        switcher.setOn(model.property.value, animated: false)
    }
    
    @objc private func executeAction() {
        action?(switcher)
    }
    
    struct Model : CellModelProtocol {
        var reuseCellIdentifier: String = "SwitchCell"
        var title: String
        var defaultValue: ()->Bool
        var switchColor: UIColor? = nil
        var hiddenCondition: (() -> Bool)? = nil
        var disableCondition: (() -> Bool)? = nil
        var tapAction : (()->())? = nil
        var action: ((UISwitch)->())
    }
    
    struct ModelProperty : CellModelProtocol {
        var reuseCellIdentifier: String = "SwitchCell"
        var title: String
        var property: UserPreferences.SettingProperty<Bool>
        var switchColor: UIColor? = nil
        var hiddenCondition: (() -> Bool)? = nil
        var disableCondition: (() -> Bool)? = nil
        var tapAction : (()->())? = nil
        var action: ((UISwitch)->())? = nil
    }
}
