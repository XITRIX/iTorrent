//
//  DisposalBag.swift
//  BinderTest
//
//  Created by Daniil Vinogradov on 21.05.2020.
//  Copyright © 2020 NoNameDude. All rights reserved.
//

import Foundation

open class DisposalBag {
    private var disposalArray = [Disposal]()
    
    deinit {
        disposeAll()
    }
    
    public func add(_ disposal: Disposal) {
        disposalArray.append(disposal)
    }
    
    public func disposeAll() {
        disposalArray.forEach { $0.dispose() }
        disposalArray.removeAll()
    }
}
