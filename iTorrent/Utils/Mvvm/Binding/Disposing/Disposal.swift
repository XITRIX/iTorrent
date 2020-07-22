//
//  Disposal.swift
//  BinderTest
//
//  Created by Daniil Vinogradov on 21.05.2020.
//  Copyright © 2020 NoNameDude. All rights reserved.
//

import Foundation

open class Disposal {
    public typealias Disposing = () -> ()
    public let dispose: Disposing
    
    public init(_ dispose: @escaping Disposing) {
        self.dispose = dispose
    }
    
    public func dispose(with disposalBag: DisposalBag) {
        disposalBag.add(self)
    }
}
