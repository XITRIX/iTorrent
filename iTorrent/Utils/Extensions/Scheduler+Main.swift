//
//  Scheduler+Main.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 24/04/2024.
//

import Foundation
import Combine

extension Scheduler where Self == DispatchQueue {
    static var main: DispatchQueue {
        DispatchQueue.main
    }

    static func global(qos: DispatchQoS.QoSClass) -> DispatchQueue {
        DispatchQueue.global(qos: qos)
    }
}
