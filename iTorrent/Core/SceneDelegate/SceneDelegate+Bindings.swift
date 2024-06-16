//
//  SceneDelegate+Bindings.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 05.04.2024.
//

import Combine
import UIKit

extension SceneDelegate {
    var tintColorBind: AnyCancellable {
        PreferencesStorage.shared.$tintColor.sink { [unowned self] color in
            window?.tintColor = color
        }
    }

    var appAppearanceBind: AnyCancellable {
        PreferencesStorage.shared.$appAppearance.sink { [unowned self] appearance in
            guard let window else { return }

            let currentAppTheme = window.traitCollection.userInterfaceStyle
            let currentDeviceTheme = window.windowScene!.traitCollection.userInterfaceStyle

            let animationNeeded: Bool
            if appearance == .unspecified {
                animationNeeded = currentAppTheme != currentDeviceTheme
            } else {
                animationNeeded = currentAppTheme != appearance
            }

            if animationNeeded {
                UIView.transition(with: window, duration: 0.3, options: [.transitionFlipFromRight]) {
                    window.overrideUserInterfaceStyle = appearance
                }
            } else {
                window.overrideUserInterfaceStyle = appearance
            }
        }
    }

    var backgroundDownloadModeBind: AnyCancellable {
        Publishers.CombineLatest(PreferencesStorage.shared.$backgroundMode, PreferencesStorage.shared.$isBackgroundDownloadEnabled)
            .sink { mode, isBackgroundDownloadEnabled in
                guard isBackgroundDownloadEnabled else { return }
                Task {
                    // If fail set audio as unfailable mode
                    if await !BackgroundService.shared.applyMode(mode) {
                        PreferencesStorage.shared.backgroundMode = .audio
                    }
                }
            }
    }
}
