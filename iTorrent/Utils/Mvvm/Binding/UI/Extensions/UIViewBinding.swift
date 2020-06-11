//
//  UIViewBinding.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 04.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

extension UIView {
    var isHiddenBox: Box<Bool> {
        let box = Box<Bool>(self.isHidden)
        box.bind { value in
            if self.isHidden != value {
                self.isHidden = value
            }
        }.dispose(with: box.disposalBag)
        return box
    }
}

class UIViewBinding {
    typealias Listener = () -> ()
    let isHiddenBox: Box<Bool>
    let disposalBag = DisposalBag()
    
    weak var view: UIView?
    
    init(_ view: UIView) {
        self.view = view
        
        isHiddenBox = Box<Bool>(view.isHidden)
        isHiddenBox.bind { (value) in
            view.isHidden = value
        }.dispose(with: disposalBag)
    }
    
    deinit {
//        print("UIBarButtonItemBinding deinit")
    }
}

extension UIViewBinding {
//    func bindTap(_ listener: @escaping Listener) -> Disposal {
//        let disposal = tapBox.bind(updateOnBind: false) { listener() }
//        return Disposal {
//            disposal.dispose()
//            self.button?.target = nil
//            self.button?.action = nil
//        }
//    }
}
