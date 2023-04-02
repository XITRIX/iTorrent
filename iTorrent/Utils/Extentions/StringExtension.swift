//
//  StringExtension.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 21.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import Foundation

extension String {
    func cString() -> UnsafeMutablePointer<Int8> {
        let count = utf8.count + 1
        let result = UnsafeMutablePointer<Int8>.allocate(capacity: count)
        withCString { baseAddress in
            result.initialize(from: baseAddress, count: count)
        }
        return result
    }

    var localized: String {
        Localize.get(self)
    }

    var isIPv4: Bool {
        var sin = sockaddr_in()
        return withCString { cstring in inet_pton(AF_INET, cstring, &sin.sin_addr) } == 1
    }

    var isIPv6: Bool {
        var sin6 = sockaddr_in6()
        return withCString { cstring in inet_pton(AF_INET6, cstring, &sin6.sin6_addr) } == 1
    }

    var isIpAddress: Bool { isIPv6 || isIPv4 }
}
