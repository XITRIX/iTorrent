//
//  InitialSetupFlowProtocol.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 23.12.2024.
//

import MvvmFoundation

protocol InitialSetupFlowProtocol {
    static var isNeeded: Bool { get }

    @MainActor
    static func screen(with completion: @escaping () -> Void) -> NavigationProtocol

    static func markDone()
}
