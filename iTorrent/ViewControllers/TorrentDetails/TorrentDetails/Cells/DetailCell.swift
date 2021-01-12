//
//  DetailCell.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 02.08.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

class DetailCell: ThemedUITableViewCell, PreferenceCellProtocol {
    static let id = "DetailCell"
    static let nib = UINib(nibName: id, bundle: nil)
    static let name = id
    
    @IBOutlet var title: ThemedUILabel!
    @IBOutlet var detail: UILabel!

    override func themeUpdate() {
        super.themeUpdate()
        let theme = Themes.current
        title?.textColor = theme.mainText
        detail?.textColor = theme.selectedText
    }

    func setModel(_ model: CellModelProtocol) {
        guard let model = model as? Model else {
            return
        }
        title.text = Localize.get(model.title)
        detail.textWithFit = Localize.get(key: model.detail())
    }

    struct Model: CellModelProtocol {
        var reuseCellIdentifier: String = id
        var title: String
        var detail: () -> String?
        var buttonTitleFunc: (() -> String)?
        var hiddenCondition: (() -> Bool)?
        var tapAction: (() -> ())?
        var longPressAction: (() -> ())?
    }
}
