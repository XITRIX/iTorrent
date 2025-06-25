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

    public static let shared = PatreonWebServer()
    override init() {
        super.init()
        addDefaultHandler(forMethod: "GET", request: GCDWebServerRequest.self) { [unowned self] request in
            defer { stop() }

            if let code = request.query?["code"] {
                DispatchQueue.main.async { [self] in
                    completion?(code)
                }
                return GCDWebServerDataResponse(text: "Done!")
            }
            DispatchQueue.main.async { [self] in
                completion?(nil)
            }
            return GCDWebServerDataResponse(text: "Failed :(")
        }
    }

    func run(completion: @escaping (String?) -> ()) throws {
        self.completion = completion
        if !isRunning {
            var options: [String: Any] = [:]
            options[GCDWebServerOption_AutomaticallySuspendInBackground] = false
            options[GCDWebServerOption_Port] = 25565
            try start(options: options)
        }
    }
}
