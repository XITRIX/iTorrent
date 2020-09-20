//
//  PatreonWebServer.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 17.04.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import Foundation
import GCDWebServer

class PatreonWebServer: GCDWebServer {
    private var completion: ((String?) -> ())!

    public static let shared = PatreonWebServer()
    override init() {
        super.init()
        addDefaultHandler(forMethod: "GET", request: GCDWebServerRequest.self) { request in
            defer { self.stop() }
            
            if let code = request.query?["code"] {
                DispatchQueue.main.async {
                    self.completion(code)
                }
                return GCDWebServerDataResponse(text: "Done!")
            }
            DispatchQueue.main.async {
                self.completion(nil)
            }
            return GCDWebServerDataResponse(text: "Failed :(")
        }
    }

    func run(completion: @escaping (String?) -> ()) {
        self.completion = completion
        if !isRunning {
            start(withPort: 25565, bonjourName: nil)
        }
    }
}
