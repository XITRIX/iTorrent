//
//  UIActivityIndicatorViewBinding.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 04.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

extension UIActivityIndicatorView {
    var isAnimatingBox: Box<Bool> {
        let box = Box<Bool>(self.isAnimating)
        box.bind { value in
            DispatchQueue.main.async {
                if value {
                    self.stopAnimating()
                } else {
                    self.startAnimating()
                }
            }
        }.dispose(with: box.disposalBag)
        return box
    }
}
