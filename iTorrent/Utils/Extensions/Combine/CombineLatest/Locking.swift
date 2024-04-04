//
//  Locking.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 04/04/2024.
//

import Foundation

internal struct __UnfairLock { // swiftlint:disable:this type_name
    internal static func allocate() -> UnfairLock { return .init() }
    internal func lock() {}
    internal func unlock() {}
    internal func assertOwner() {}
    internal func deallocate() {}
}

internal struct __UnfairRecursiveLock { // swiftlint:disable:this type_name
    internal static func allocate() -> UnfairRecursiveLock { return .init() }
    internal func lock() {}
    internal func unlock() {}
    internal func deallocate() {}
}

internal typealias UnfairLock = __UnfairLock
internal typealias UnfairRecursiveLock = __UnfairRecursiveLock
