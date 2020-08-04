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

    func setModel(_ model: CellModelProtocol) {
        guard let model = model as? Model else {
            return
        }
        title.text = Localize.get(model.title)
        title.font = model.titleFont
    }

    struct Model: CellModelProtocol {
        var reuseCellIdentifier: String = id
        var title: String
        var titleFont: UIFont?
        var segueViewId: String?
        var controller: UIViewController?
        var controllerType: UIViewController.Type?
        var hiddenCondition: (() -> Bool)?
        var tapAction: (() -> ())?
        var longPressAction: (() -> ())?

        init(title: String, titleFont: UIFont? = nil, tapAction: @escaping () -> ()) {
            self.title = title
            self.titleFont = titleFont
            self.tapAction = tapAction
        }

        init(_ vc: UIViewController?, title: String, titleFont: UIFont? = nil, segueViewId: String, isModal: Bool = false) {
            self.title = title
            self.titleFont = titleFont
            self.segueViewId = segueViewId

            tapAction = { [weak vc] in
                if let tvc = UIApplication.shared.keyWindow?.rootViewController?.storyboard?.instantiateViewController(withIdentifier: segueViewId) {
                    if isModal {
                        vc?.present(tvc, animated: true)
                    } else {
                        vc?.show(tvc, sender: vc)
                    }
                }
            }
        }

        init(_ vc: UIViewController?, title: String, titleFont: UIFont? = nil, controllerType: UIViewController.Type, isModal: Bool = false) {
            self.title = title
            self.titleFont = titleFont
            self.controllerType = controllerType

            tapAction = { [weak vc] in
                if isModal {
                    vc?.present(controllerType.init(), animated: true)
                } else {
                    vc?.show(controllerType.init(), sender: vc)
                }
            }
        }

        init(_ vc: UIViewController?, title: String, titleFont: UIFont? = nil, controller: UIViewController, isModal: Bool = false) {
            self.title = title
            self.titleFont = titleFont
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
