//
//  BoxCombiner.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 30.05.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import Foundation

class BoxCombiner {
    static func bind<T1, T2>(_ box1: Box<T1>, _ box2: Box<T2>, updateOnBind: Bool = true, listener: @escaping (T1, T2) -> ()) -> Disposal {
        let disposal1 = box1.bind(updateOnBind: false) { value in
            listener(value, box2.variable)
        }
        
        let disposal2 = box2.bind(updateOnBind: false) { value in
            listener(box1.variable, value)
        }
        
        if updateOnBind {
            listener(box1.variable, box2.variable)
        }
        
        return Disposal {
            disposal1.dispose()
            disposal2.dispose()
        }
    }
    
    static func bind<T1, T2, T3>(_ box1: Box<T1>, _ box2: Box<T2>, _ box3: Box<T3>, updateOnBind: Bool = true, listener: @escaping (T1, T2, T3) -> ()) -> Disposal {
        let disposal1 = bind(box1, box2, updateOnBind: false) { value1, value2 in
            listener(value1, value2, box3.variable)
        }
        
        let disposal2 = box3.bind(updateOnBind: false) { value in
            listener(box1.variable, box2.variable, value)
        }
        
        if updateOnBind {
            listener(box1.variable, box2.variable, box3.variable)
        }
        
        return Disposal {
            disposal1.dispose()
            disposal2.dispose()
        }
    }
}
