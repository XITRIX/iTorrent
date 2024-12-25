//
//  PatreonPreferencesViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 24/04/2024.
//

import MvvmFoundation
import Combine
import UIKit

extension PatreonPreferencesViewModel {
    enum PatreonAccountState: Equatable {
        case none
        case auth(PatreonAccount)
        case loading
    }
}

class PatreonPreferencesViewModel: BaseViewModel, @unchecked Sendable {
    let accountState = CurrentValueSubject<PatreonAccountState, Never>(.none)

    required init() {
        super.init()

        if let patreonAccount = preferencesStorage.patreonAccount {
            accountState.value = .auth(patreonAccount)
        } else {
            accountState.value = .none
        }
    }

    @Injected private var patreonService: PatreonService
    @Injected private var preferencesStorage: PreferencesStorage
}

extension PatreonPreferencesViewModel {
    var linkButtonTitle: AnyPublisher<String, Never> {
        accountState.map { account in
            switch account {
            case .auth(let account):
                return "\(%"patreon.action.unlink") \(account.name)"
            case .loading:
                return ""
            case .none:
                return %"patreon.action.link"
            }
        }.eraseToAnyPublisher()
    }

    var versionTextPublisher: AnyPublisher<String?, Never> {
        preferencesStorage.$patreonAccount.map { account -> String? in
            guard let account else { return nil }

            if account.fullVersion {
                return %"patreon.status.full"
            }

            if account.isPatron {
                return %"patreon.status.parton"
            }

            return nil
        }.eraseToAnyPublisher()
    }

    var isPatronPublisher: AnyPublisher<Bool, Never> {
        preferencesStorage.$patreonAccount.map { $0?.isPatron ?? false }.eraseToAnyPublisher()
    }

    var isFullVersionPublisher: AnyPublisher<Bool, Never> {
        preferencesStorage.$patreonAccount.map { $0?.fullVersion ?? false }.eraseToAnyPublisher()
    }

    @MainActor
    func linkPatreon(from view: UIView) {
        if accountState.value == .none {
            guard let context = navigationService?()
            else { return }
            
            Task {
                do {
                    accountState.value = .loading
                    accountState.value = .auth(try await patreonService.authenticate(from: context))
                } catch {
                    accountState.value = .none
                }
            }
        } else {
            alert(title: %"patreon.action.unlink.title",style: .actionSheet, actions: [
                .init(title: %"common.cancel", style: .cancel),
                .init(title: %"patreon.action.unlink.button", style: .destructive) { [unowned self] in
                    try? patreonService.signOut()
                    accountState.value = .none
                }
            ], sourceView: view)
        }
    }
}
