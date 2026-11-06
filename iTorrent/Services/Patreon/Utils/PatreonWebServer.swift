//
//  PatreonWebServer.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 10/05/2024.
//

import Foundation
import GCDWebServers

class PatreonWebServer: GCDWebServer, @unchecked Sendable {
    private var completion: ((String?) -> ())?
    private let completionLock = NSLock()

    enum AuthenticationError: Swift.Error {
        case alreadyInProgress
    }

    public static let shared = PatreonWebServer()
    override init() {
        super.init()
        addDefaultHandler(forMethod: "GET", request: GCDWebServerRequest.self) { [unowned self] request in
            defer { stop() }

            if let code = request.query?["code"] {
                DispatchQueue.main.async { [self] in
                    complete(with: code)
                }
                return GCDWebServerDataResponse(text: "Done!")
            }
            DispatchQueue.main.async { [self] in
                complete(with: nil)
            }
            return GCDWebServerDataResponse(text: "Failed :(")
        }
    }

    func run(completion: @escaping (String?) -> ()) throws {
        completionLock.lock()
        defer { completionLock.unlock() }
        guard self.completion == nil else { throw AuthenticationError.alreadyInProgress }
        self.completion = completion
        do {
            if !isRunning {
                var options: [String: Any] = [:]
                options[GCDWebServerOption_AutomaticallySuspendInBackground] = false
                options[GCDWebServerOption_Port] = 25565
                try start(options: options)
            }
        } catch {
            self.completion = nil
            throw error
        }
    }

    private func complete(with code: String?) {
        completionLock.lock()
        let callback = completion
        completion = nil
        completionLock.unlock()
        callback?(code)
    }
}
