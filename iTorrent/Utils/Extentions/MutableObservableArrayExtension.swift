//
//  MutableObservableArrayExtension.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 20.10.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import Bond

extension Observable {
    func notifyUpdate() {
        on(.next(value))
    }
}
