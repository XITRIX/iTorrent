//
//  Core+WebDavServer.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 30.03.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import Foundation
import GCDWebServer

extension Core {
    func startFileSharing() {
        var options = [String: Any]()

        if !UserPreferences.webDavUsername.value.isEmpty {
            options[GCDWebServerOption_AuthenticationAccounts] = [UserPreferences.webDavUsername.value: UserPreferences.webDavPassword.value]
            options[GCDWebServerOption_AuthenticationMethod] = GCDWebServerAuthenticationMethod_DigestAccess
        }

        if UserPreferences.webDavWebServerEnabled.value {
            options[GCDWebServerOption_Port] = 80
            if !webUploadServer.isRunning {
                if (try? webUploadServer.start(options: options)) == nil {
                    repeat {
                        options[GCDWebServerOption_Port] = Int.random(in: 49152 ..< 65535)
                    } while (try? webUploadServer.start(options: options)) == nil
                }
            }
        }

        if UserPreferences.webDavWebDavServerEnabled.value {
            options[GCDWebServerOption_Port] = UserPreferences.webDavPort.value
            if !webDAVServer.isRunning {
                try? webDAVServer.start(options: options)
            }
        }
    }

    func stopFileSharing() {
        if webUploadServer.isRunning {
            webUploadServer.stop()
        }
        if webDAVServer.isRunning {
            webDAVServer.stop()
        }
    }
}
