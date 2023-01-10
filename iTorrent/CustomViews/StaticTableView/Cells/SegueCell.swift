//
//  SegueCell.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 02.09.2019.
//  Copyright © 2019  XITRIX. All rights reserved.
//

import UIKit

class SegueCell: ThemedUITableViewCell, PreferenceCellProtocol {
    static let id = "SegueCell"
    static let nib = UINib(nibName: id, bundle: Bundle.main)
    static let name = id

    @IBOutlet var title: ThemedUILabel!

    override func themeUpdate() {
        super.themeUpdate()
        selectedBackgroundView = nil
    }

    func setModel(_ model: CellModelProtocol) {
        guard let model = model as? Model else {
            return
        }
        title.text = Localize.get(model.title)
        title.font = model.bold ? title.font.bold() : title.font.normal()

        selectionStyle = model.tapAction == nil ? .none : .default
    }

    struct Model: CellModelProtocol {
        var reuseCellIdentifier: String = id
        var title: String
        var bold: Bool = false
        var segueViewId: String?
        var controller: UIViewController?
        var controllerType: UIViewController.Type?
        var hiddenCondition: (() -> Bool)?
        var tapAction: (() -> ())?
        var longPressAction: (() -> ())?

        init(title: String, bold: Bool = false, tapAction: @escaping () -> ()) {
            self.title = title
            self.bold = bold
            self.tapAction = tapAction
        }

        init(_ vc: UIViewController?, title: String, bold: Bool = false, segueViewId: String, isModal: Bool = false) {
            self.title = title
            self.bold = bold
            self.segueViewId = segueViewId

            tapAction = { [weak vc] in
                let tvc = Utils.mainStoryboard.instantiateViewController(withIdentifier: segueViewId)
                if isModal {
                    vc?.present(tvc, animated: true)
                } else {
                    vc?.show(tvc, sender: vc)
                }
            }
        }

        init(_ vc: UIViewController?, title: String, bold: Bool = false, controllerType: UIViewController.Type, isModal: Bool = false) {
            self.title = title
            self.bold = bold
            self.controllerType = controllerType

            tapAction = { [weak vc] in
                if isModal {
                    vc?.present(controllerType.init(), animated: true)
                } else {
                    vc?.show(controllerType.init(), sender: vc)
                }
            }
        }

        init(_ vc: UIViewController?, title: String, bold: Bool = false, controller: UIViewController, isModal: Bool = false) {
            self.title = title
            self.bold = bold
            self.controller = controller

            tapAction = { [weak vc] in
                if isModal {
                    vc?.present(controller, animated: true)
                } else {
                    vc?.show(controller, sender: vc)
                }
            }
        }
    }
}
