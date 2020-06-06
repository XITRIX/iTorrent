//
//  UITableViewCellBind.swift
//  BinderTest
//
//  Created by Daniil Vinogradov on 25.05.2020.
//  Copyright © 2020 NoNameDude. All rights reserved.
//

import UIKit

class BindableUITableViewCell<T>: UITableViewCell {
    let disposalBag = DisposalBag()
    var model: T?
    
    func setModel(_ model: T) {
        self.model = model
        binding()
    }
    
    func binding() {
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposalBag.disposeAll()
    }
}
