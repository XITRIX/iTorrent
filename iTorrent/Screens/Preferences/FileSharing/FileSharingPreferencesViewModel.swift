//
//  FileSharingPreferencesViewModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 23.04.2024.
//

import Combine
import LibTorrent
import MvvmFoundation
import UIKit

class FileSharingPreferencesViewModel: BasePreferencesViewModel {
    required init() {
        super.init()
        binding()
        reload()
    }

    private lazy var loginVM = PRButtonViewModel(with: .init(title: %"common.login") { [unowned self] in
        textInput(title: %"common.login", placeholder: %"common.login", defaultValue: "\(preferences.webServerLogin)") { [unowned self] res in
            dismissSelection.send()
            guard let res else { return }
            preferences.webServerLogin = res
        }
    })

    private lazy var passwordVM = PRButtonViewModel(with: .init(title: %"common.password") { [unowned self] in
        textInput(title: %"common.password", placeholder: %"common.password", defaultValue: "\(preferences.webServerPassword)", secured: true) { [unowned self] res in
            dismissSelection.send()
            guard let res else { return }
            preferences.webServerPassword = res
        }
    })

    private let preferences = PreferencesStorage.shared
}

private extension FileSharingPreferencesViewModel {
    var commonBinding: AnyPublisher<Void, Never> {
        Just(())
            .combineLatest(preferences.$isFileSharingEnabled)
            .combineLatest(preferences.$isWebServerEnabled)
            .combineLatest(preferences.$isWebDavServerEnabled)
            .combineLatest(preferences.$webServerLogin)
            .combineLatest(preferences.$webServerPassword)
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    func binding() {
        disposeBag.bind {
            commonBinding
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: { [unowned self] _ in reload() })

            preferences.$webServerLogin.sink { [unowned self] login in
                loginVM.value = !login.isEmpty ? login : %"common.optional"
                loginVM.tinted = !login.isEmpty
            }

            preferences.$webServerPassword.map { String($0).map { _ in "•" }.joined() }
                .sink { [unowned self] password in
                    passwordVM.value = !password.isEmpty ? password : %"common.optional"
                    passwordVM.tinted = !password.isEmpty
                }
        }
    }

    func reload() {
        title.send(%"preferences.sharing")

        var sections: [MvvmCollectionSectionModel] = []
        defer { self.sections.send(sections) }

        sections.append(.init(id: "settings", header: %"preferences.sharing.authorization") {
            loginVM

            if !preferences.webServerLogin.isEmpty {
                passwordVM
            }
        })

        sections.append(.init(id: "webserver", header: %"preferences.sharing.webserver", footer: %"preferences.sharing.webserver.footer") {
            PRSwitchViewModel(with: .init(id: "web", title: %"common.enable", value: preferences.$isWebServerEnabled.binding))
        })

        sections.append(.init(id: "webdavserver", header: %"preferences.sharing.webdavserver", footer: %"preferences.sharing.webdavserver.footer") {
            PRSwitchViewModel(with: .init(id: "webdav", title: %"common.enable", value: preferences.$isWebDavServerEnabled.binding))

            PRButtonViewModel(with: .init(title: %"common.port", value: preferences.$webDavServerPort.map { String($0) }.eraseToAnyPublisher()) { [unowned self] in
                textInput(title: %"common.port", placeholder: "81", defaultValue: "\(preferences.webDavServerPort)", type: .numberPad) { [unowned self] res in
                    dismissSelection.send()
                    guard let res else { return }
                    preferences.webDavServerPort = Int(res) ?? 81
                }
            })

        })
    }
}
