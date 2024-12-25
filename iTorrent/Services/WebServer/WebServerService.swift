//
//  WebServerService.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 23/04/2024.
//

import Combine
import GCDWebServers
import MvvmFoundation
import UIKit

class WebServerService: Resolvable, @unchecked Sendable {
    init() { binding() }

    @Published var isWebServerEnabled: Bool = false
    @Published var isWebDavServerEnabled: Bool = false

    @Published var ip: String?
    @Published var webPort: UInt?
    @Published var webDavPort: UInt?

    private var webUploadServer = GCDWebUploader(uploadDirectory: TorrentService.downloadPath.path())
    private var webDAVServer = GCDWebDAVServer(uploadDirectory: TorrentService.downloadPath.path())

    private let disposeBag = DisposeBag()
    private var backgroundDisposeBag: DisposeBag?

    @Injected private var preferences: PreferencesStorage
    @Injected private var backgroundService: BackgroundService
    @Injected private var networkMonitoringService: NetworkMonitoringService
}

extension WebServerService {
    var connectionHint: AnyPublisher<String, Never> {
        Publishers.combineLatest(preferences.$isFileSharingEnabled, $ip, $webPort, $webDavPort) { enabled, ip, webPort, webDavPort in
            guard enabled else { return "" }

            var arr: [String] = []
            if let webPort = webPort {
                arr.append("Web:\(webPort)")
            }
            if let webDavPort = webDavPort {
                arr.append("WebDav:\(webDavPort)")
            }

            // If empty, they disabled
            guard !arr.isEmpty else { return "" }

            // If not disabled, but no ip - server is unreachable
            guard let ip else { return %"webserver.unavailable" }

            return "\(ip)  —  \(arr.joined(separator: " | "))"
        }
        .eraseToAnyPublisher()
    }
}

// MARK: Internal publishers
private extension WebServerService {
    var ipPublisher: AnyPublisher<String?, Never> {
        Publishers.combineLatest(
            $isWebServerEnabled,
            $isWebDavServerEnabled,
            networkMonitoringService.$availableInterfaces)
        { [unowned self] _, _, _ in
            guard let host = webUploadServer.serverURL?.host() ?? webDAVServer.serverURL?.host()
            else { return nil }
            return "http://" + host
        }
        .debounce(for: 0.1, scheduler: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    var webPortPublisher: AnyPublisher<UInt?, Never> {
        $isWebServerEnabled.map { [unowned self] _ in
            guard webUploadServer.isRunning else { return nil }
            return webUploadServer.port
        }.eraseToAnyPublisher()
    }

    var webDavPortPublisher: AnyPublisher<UInt?, Never> {
        $isWebDavServerEnabled.map { [unowned self] _ in
            guard webDAVServer.isRunning else { return nil }
            return webDAVServer.port
        }.eraseToAnyPublisher()
    }
}

private extension WebServerService {
    var commonBinding: AnyPublisher<Void, Never> {
        Just(())
            .combineLatest(preferences.$isFileSharingEnabled)
            .combineLatest(preferences.$webServerLogin)
            .combineLatest(preferences.$webServerPassword)
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    var options: [String: Any] {
        var options: [String: Any] = [:]

        if !preferences.webServerLogin.isEmpty {
            options[GCDWebServerOption_AuthenticationAccounts] = [preferences.webServerLogin: preferences.webServerPassword]
            options[GCDWebServerOption_AuthenticationMethod] = GCDWebServerAuthenticationMethod_DigestAccess
        }

        options[GCDWebServerOption_AutomaticallySuspendInBackground] = false

        return options
    }

    func binding() {
        disposeBag.bind {
            Just(())
                .combineLatest(commonBinding)
                .combineLatest(preferences.$isWebServerEnabled)
                .combineLatest(preferences.$webServerPort)
                .sink { [unowned self] _ in
                    Task.detached(priority: .utility) { await self.refreshWebServerState() }
                }

            Just(())
                .combineLatest(commonBinding)
                .combineLatest(preferences.$isWebDavServerEnabled)
                .combineLatest(preferences.$webDavServerPort)
                .sink { [unowned self] _ in
                    Task.detached(priority: .utility) { await self.refreshWebDavServerState() }
                }

            NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
                .sink { [unowned self] _ in
                    Task.detached(priority: .utility) { await self.invalidateBackgroundState(true) }
                }

            NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
                .sink { [unowned self] _ in
                    Task.detached(priority: .utility) { await self.invalidateBackgroundState(false) }
                }
        }

        ipPublisher.assign(to: &$ip)
        webPortPublisher.assign(to: &$webPort)
        webDavPortPublisher.assign(to: &$webDavPort)
    }

    @MainActor
    func invalidateBackgroundState(_ goToBackground: Bool) async {
//        print("WebService test: \(goToBackground) && \(backgroundService.isRunning)")

        backgroundDisposeBag = DisposeBag()

        let suspendServers = { [unowned self] in
            print("Suspending servers")
            Task.detached(priority: .utility) { [self] in
                if webUploadServer.isRunning {
                    webUploadServer.stop()
                    await MainActor.run {
                        isWebServerEnabled = false
                    }
                }

                if webDAVServer.isRunning {
                    webDAVServer.stop()
                    await MainActor.run {
                        isWebDavServerEnabled = false
                    }
                }
            }
        }

        if goToBackground { // Going background
            if backgroundService.isRunning {
                backgroundDisposeBag?.bind {
                    backgroundService.$isRunningPublisher
                        // Wait a bit to allow unbind before triggering on going foreground
                        .debounce(for: 0.1, scheduler: DispatchQueue.main)
                        .sink { [unowned self] isRunning in
                            guard !isRunning else { return }
                            suspendServers()
                            backgroundDisposeBag = nil
                        }
                }
            } else {
                suspendServers()
            }
        } else { // Going foreground
            if !webUploadServer.isRunning {
                await refreshWebServerState()
            }

            if !webDAVServer.isRunning {
                await refreshWebDavServerState()
            }
        }
    }

    func refreshWebServerState() async {
        let needToEnable = preferences.isFileSharingEnabled && preferences.isWebServerEnabled

        if webUploadServer.isRunning {
            webUploadServer.stop()
            await MainActor.run {
                isWebServerEnabled = false
            }
        }

        if needToEnable, !webUploadServer.isRunning {
            var localOptions = options
            var port = preferences.webServerPort
            localOptions[GCDWebServerOption_Port] = port
            while (try? webUploadServer.start(options: localOptions)) == nil {
                port += 1
                localOptions[GCDWebServerOption_Port] = port
            }
            await MainActor.run {
                isWebServerEnabled = true
            }
        }
    }

    func refreshWebDavServerState() async {
        let needToEnable = preferences.isFileSharingEnabled && preferences.isWebDavServerEnabled

        if webDAVServer.isRunning {
            webDAVServer.stop()
            await MainActor.run {
                isWebDavServerEnabled = false
            }
        }

        if needToEnable, !webDAVServer.isRunning {
            var localOptions = options
            var port = preferences.webDavServerPort
            localOptions[GCDWebServerOption_Port] = port
            while (try? webDAVServer.start(options: localOptions)) == nil {
                port += 1
                localOptions[GCDWebServerOption_Port] = port
            }
            await MainActor.run {
                isWebDavServerEnabled = true
            }
        }
    }
}
