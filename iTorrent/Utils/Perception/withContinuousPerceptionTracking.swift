//
//  withContinuousPerceptionTracking.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 11.06.2026.
//

import Perception
import Foundation

public func withContinuousPerceptionTracking(_ apply: @escaping @Sendable () -> Void) {
    withPerceptionTracking {
        apply()
    } onChange: {
        DispatchQueue.main.async {
            withContinuousPerceptionTracking(apply)
        }
    }
}
