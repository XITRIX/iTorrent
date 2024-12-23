//
//  CellularToggleSetupViewModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 23.12.2024.
//

import UIKit
import MvvmFoundation

extension CellularToggleSetupViewModel {
    struct Config {
        var completion: () -> Void
    }
}

class CellularToggleSetupViewModel: BaseViewModelWith<CellularToggleSetupViewModel.Config> {
    override func prepare(with model: Config) {
        completion = model.completion
    }

    func disableCellularAction() {
        PreferencesStorage.shared.isCellularEnabled = false
        completion()

    }

    func allowCellularAction() {
        alert(title: %"initialSetup.cellular.allowCheck.title", style: .actionSheet, actions: [
            .init(title: %"common.cancel", style: .cancel),
            .init(title: %"initialSetup.cellular.allowCheck.confirm", style: .destructive, action: { [unowned self] in
                PreferencesStorage.shared.isCellularEnabled = true
                completion()
            })
        ])
    }

    private var completion: (() -> Void)!
}

extension CellularToggleSetupViewModel: InitialSetupFlowProtocol {
    static var isNeeded: Bool {
        !PreferencesStorage.shared.initialSetupCellularPassed
    }

    static func screen(with completion: @escaping () -> Void) -> NavigationProtocol {
        CellularToggleSetupViewModel.resolveVC(with: .init(completion: completion))
    }

    static func markDone() {
        PreferencesStorage.shared.initialSetupCellularPassed = true
    }
}
