//
//  Bindable+Value.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 24.04.2022.
//

import Bond

infix operator =?
public func =?<T>(lhs: Observable<T>, rhs: T) where T: Equatable {
    guard lhs.value != rhs else { return }
    lhs.value = rhs
}
