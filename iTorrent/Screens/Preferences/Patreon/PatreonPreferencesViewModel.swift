//
//  PatreonPreferencesViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 24/04/2024.
//

import MvvmFoundation
import Combine

class PatreonPreferencesViewModel: BaseViewModel {
    @Injected private var patreonService: PatreonService
    @Injected private var preferencesStorage: PreferencesStorage
}

extension PatreonPreferencesViewModel {
    var linkButtonTitle: AnyPublisher<String, Never> {
        preferencesStorage.$patreonAccount.map { account in
            if let account {
                return "\(%"patreon.action.unlink") \(account.name)"
            } else {
                return %"patreon.action.link"
            }
        }.eraseToAnyPublisher()
    }

    var accountPublisher: AnyPublisher<PatreonAccount?, Never> {
        preferencesStorage.$patreonAccount.eraseToAnyPublisher()
    }

    var isPatronPublisher: AnyPublisher<Bool, Never> {
        preferencesStorage.$patreonAccount.map { $0?.isPatron ?? false }.eraseToAnyPublisher()
    }

    var isFullVersionPublisher: AnyPublisher<Bool, Never> {
        preferencesStorage.$patreonAccount.map { $0?.fullVersion ?? false }.eraseToAnyPublisher()
    }

    func linkPatreon() {
        if !patreonService.isAuthenticated {
            guard let context = navigationService?()
            else { return }
            
            Task {
                try await patreonService.authenticate(from: context)
            }
        } else {
            alert(title: %"patreon.action.unlink.title",style: .actionSheet, actions: [
                .init(title: %"common.cancel", style: .cancel),
                .init(title: %"patreon.action.unlink.button", style: .destructive) { [unowned self] in
                    try? patreonService.signOut()
                }
            ])
        }
    }
}
