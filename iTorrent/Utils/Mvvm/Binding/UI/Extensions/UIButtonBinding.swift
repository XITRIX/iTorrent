//
//  UIButtonBind.swift
//  BinderTest
//
//  Created by Daniil Vinogradov on 21.05.2020.
//  Copyright © 2020 NoNameDude. All rights reserved.
//

import UIKit

extension UIButton {
    var asBindable: UIButtonBinding {
        UIButtonBinding(self)
    }
}

class UIButtonBinding {
    typealias Listener = () -> ()
    let tapBox = Box<Void>(())
    
    weak var button: UIButton?
    
    init(_ button: UIButton) {
        self.button = button
        button.addTarget(self, action: #selector(touchUpInside), for: .touchUpInside)
    }
    
    @objc private func touchUpInside() {
        tapBox.variable = ()
    }
    
    deinit {
//        print("UIButtonBinding deinit")
    }
}

extension UIButtonBinding {
    func bindTap(_ listener: @escaping Listener) -> Disposal {
        let disposal = tapBox.bind(updateOnBind: false) { listener() }
        return Disposal {
            disposal.dispose()
//            self.button?.removeTarget(self, action: #selector(self.touchUpInside), for: .touchUpInside)
        }
    }
}
