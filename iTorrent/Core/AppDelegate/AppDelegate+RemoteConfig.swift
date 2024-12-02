//
//  AppDelegate+RemoteConfig.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 19.04.2024.
//

import UIKit
#if canImport(FirebaseCore)
import FirebaseRemoteConfig
let remoteConfig = RemoteConfig.remoteConfig()
#endif

extension AppDelegate {
    func registerRemoteConfig() {
#if canImport(FirebaseCore)
        registerKillSwitch()
#endif
    }
}

#if canImport(FirebaseCore)
private extension AppDelegate {
    func registerKillSwitch() {
        remoteConfig.fetchAndActivate { [unowned self] status, error in
            guard error == nil, status == .successFetchedFromRemote else { return }
            Task { try await checkKillSwitch() }
        }

        remoteConfig.addOnConfigUpdateListener { [unowned self] _, error in
            guard error == nil else { return }

            remoteConfig.activate { [unowned self] _, _ in
                Task { try await checkKillSwitch() }
            }
        }
    }

    @MainActor
    func checkKillSwitch() async throws {
        guard remoteConfig.configValue(forKey: "disabledBuilds").boolValue else { return }

        guard let keyWindow = UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows
            .first(where: { $0.isKeyWindow }),
            let topController = keyWindow.rootViewController?.topPresented
        else {
            exit(0)
        }

        let alert = UIAlertController(title: %"expire.title", message: %"expire.message", preferredStyle: .alert)
        alert.addAction(.init(title: %"expire.update", style: .cancel) { _ in
            Task {
                let updateURL: URL 
                if let remoteURI = remoteConfig.configValue(forKey: "updateURL").stringValue,
                   let remoteURL = URL(string: remoteURI) {
                    updateURL = remoteURL
                } else {
                    updateURL = URL(string: "https://github.com/XITRIX/iTorrent")!
                }

                await UIApplication.shared.open(updateURL)
                try await Task.sleep(for: .seconds(1))
                exit(0)
            }
        })
        alert.addAction(.init(title: %"expire.exit", style: .destructive) { _ in
            exit(0)
        })

        topController.present(alert, animated: true)
    }
}
#endif
