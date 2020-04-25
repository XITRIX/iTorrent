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
        title?.text = Localize.get(model.title)
    }

    struct Model: CellModelProtocol {
        var reuseCellIdentifier: String = id
        var title: String
        var segueViewId: String?
        var controller: UIViewController?
        var controllerType: UIViewController.Type?
        var hiddenCondition: (() -> Bool)?
        var tapAction: (() -> ())?

        init(title: String, tapAction: @escaping () -> ()) {
            self.title = title
            self.tapAction = tapAction
        }

        init(_ vc: UIViewController, title: String, segueViewId: String, isModal: Bool = false) {
            self.title = title
            self.segueViewId = segueViewId

            tapAction = {
                if let tvc = UIApplication.shared.keyWindow?.rootViewController?.storyboard?.instantiateViewController(withIdentifier: segueViewId) {
                    if isModal {
                        vc.present(tvc, animated: true)
                    } else {
                        vc.show(tvc, sender: vc)
                    }
                }
            }
        }

        init(_ vc: UIViewController, title: String, controllerType: UIViewController.Type, isModal: Bool = false) {
            self.title = title
            self.controllerType = controllerType

            tapAction = {
                if isModal {
                    vc.present(controllerType.init(), animated: true)
                } else {
                    vc.show(controllerType.init(), sender: vc)
                }
            }
        }

        init(_ vc: UIViewController, title: String, controller: UIViewController, isModal: Bool = false) {
            self.title = title
            self.controller = controller

            tapAction = {
                if isModal {
                    vc.present(controller, animated: true)
                } else {
                    vc.show(controller, sender: vc)
                }
            }
        }
    }
}
