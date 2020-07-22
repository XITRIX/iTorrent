//
//  UIBarButtonItemBind.swift
//  BinderTest
//
//  Created by Daniil Vinogradov on 21.05.2020.
//  Copyright © 2020 NoNameDude. All rights reserved.
//

import UIKit

extension UIBarButtonItem {
    var asBindable: UIBarButtonItemBinding {
        UIBarButtonItemBinding(self)
    }
}

class UIBarButtonItemBinding {
    typealias Listener = () -> ()
    let tapBox = Box<Void>(())
    
    weak var button: UIBarButtonItem?
    
    init(_ button: UIBarButtonItem) {
        self.button = button
        button.target = self
        button.action = #selector(touchUpInside)
    }
    
    @objc private func touchUpInside() {
        tapBox.variable = ()
    }
    
    deinit {
//        print("UIBarButtonItemBinding deinit")
    }
}

extension UIBarButtonItemBinding {
    func bindTap(_ listener: @escaping Listener) -> Disposal {
        let disposal = tapBox.bind(updateOnBind: false) { listener() }
        return Disposal {
            disposal.dispose()
//            self.button?.target = nil
//            self.button?.action = nil
        }
    }
}
