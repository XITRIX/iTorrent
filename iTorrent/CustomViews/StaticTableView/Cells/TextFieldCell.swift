//
//  TextFieldCell.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 12.11.2019.
//  Copyright © 2019  XITRIX. All rights reserved.
//

import UIKit

class TextFieldCell: ThemedUITableViewCell, PreferenceCellProtocol {
    static let id = "TextFieldCell"
    static let nib = UINib.init(nibName: id, bundle: nil)
    static let name = id
    
    @IBOutlet var title: UILabel!
    @IBOutlet var textField: UITextField!
    
    var textEditAction: ((String) -> ())?
    
    override func themeUpdate() {
        super.themeUpdate()
        let theme = Themes.current
        title?.textColor = theme.mainText
        textField?.textColor = theme.mainText
    }
    
    func setModel(_ model: CellModelProtocol) {
        guard let model = model as? Model else {
            return
        }
        self.title.text = Localize.get(model.title)
        self.textField.text = model.defaultValue()
        self.textEditAction = model.textEditAction
        
        textField.placeholder = Localize.get(model.placeholder ?? "")
        textField.isSecureTextEntry = model.isPassword
        textField.keyboardType = model.keyboardType
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            textField.becomeFirstResponder()
        }
    }
    
    @objc func textFieldDidChange() {
        if let text = textField.text {
            textEditAction?(text)
        }
    }

    struct Model: CellModelProtocol {
        var reuseCellIdentifier: String = id
        var title: String
        var placeholder: String?
        var defaultValue: () -> String
        var isPassword: Bool = false
        var keyboardType: UIKeyboardType = .default
        var hiddenCondition: (() -> Bool)? = nil
        var tapAction: (() -> ())? = nil
        var textEditAction: ((String) -> ())? = nil
    }
}
