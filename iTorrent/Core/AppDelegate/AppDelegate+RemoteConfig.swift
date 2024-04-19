//
//  AppDelegate+RemoteConfig.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 19.04.2024.
//

import Foundation
#if canImport(FirebaseCore)
import FirebaseRemoteConfig
var remoteConfig = RemoteConfig.remoteConfig()
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
    static var killSwitchFuseKey: String {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        return "KillSwitchFuze-\(appVersion)"
    }

    func registerKillSwitch() {
        checkKillSwitch()

        remoteConfig.fetchAndActivate { [unowned self] status, error in
            guard error == nil, status == .successFetchedFromRemote else { return }
            burnKillSwitchFuzeIfNeeded()
            checkKillSwitch()
        }

        remoteConfig.addOnConfigUpdateListener { [unowned self] _, error in
            guard error == nil else { return }

            remoteConfig.activate { [unowned self] _, _ in
                burnKillSwitchFuzeIfNeeded()
                checkKillSwitch()
            }
        }
    }

    func checkKillSwitch() {
        guard UserDefaults.standard.bool(forKey: Self.killSwitchFuseKey) else { return }
        exit(0)
    }

    func burnKillSwitchFuzeIfNeeded() {
        let config = remoteConfig.configValue(forKey: "disabledBuilds")
        guard config.boolValue else { return }
        UserDefaults.standard.set(true, forKey: Self.killSwitchFuseKey)
    }
}
#endif
