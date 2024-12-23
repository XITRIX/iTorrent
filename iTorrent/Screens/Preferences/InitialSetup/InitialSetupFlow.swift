//
//  InitialSetupFlow.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 23.12.2024.
//

import UIKit

class InitialSetupFlow {
    private static let setupStack: [InitialSetupFlowProtocol.Type] = [
        CellularToggleSetupViewModel.self
    ]

    @MainActor
    static func startIfNeeded() async {
        let keyWindow = UIApplication.shared.keySceneWindow
        let filteredSetupStack = setupStack.filter { $0.isNeeded }

        guard !filteredSetupStack.isEmpty,
              let topController = keyWindow.rootViewController?.topPresented
        else { return }

        let context = UINavigationController.resolve()
        topController.present(context, animated: true)

        var animate: Bool = false
        for setup in filteredSetupStack {
            await withCheckedContinuation { continuation in
                context.setViewControllers([setup.screen {
                    setup.markDone()
                    continuation.resume()
                }], animated: animate)
            }
            animate = true
        }

        topController.dismiss(animated: true)
    }
}
