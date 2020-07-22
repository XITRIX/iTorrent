//
//  SettingsPack.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 19.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import Foundation

enum ProxyType: Int, CaseIterable, Codable {
    case none
    case socks4
    case socks5
    case http
    case i2p_proxy

    var title: String {
        switch self {
        case .none:
            return Localize.get("None")
        case .socks4:
            return Localize.get("SOCKS4")
        case .socks5:
            return Localize.get("SOCKS5")
        case .http:
            return Localize.get("HTTP")
        case .i2p_proxy:
            return Localize.get("I2P")
        }
    }
}

struct SettingsPack {
    var downloadLimit: Int
    var uploadLimit: Int

    var enableDht: Bool
    var enableLsd: Bool
    var enableUtp: Bool
    var enableUpnp: Bool
    var enableNatpmp: Bool

    var portRangeFirst: Int
    var portRangeSecond: Int

    var proxyType: ProxyType
    var proxyRequiresAuth: Bool
    var proxyHostname: String
    var proxyPort: Int
    var proxyUsername: String
    var proxyPassword: String
    var proxyPeerConnections: Bool

    func asNative() -> settings_pack_struct {
        settings_pack_struct(download_limit: Int32(downloadLimit),
                             upload_limit: Int32(uploadLimit),
                             enable_dht: enableDht,
                             enable_lsd: enableLsd,
                             enable_utp: enableUtp,
                             enable_upnp: enableUpnp,
                             enable_natpmp: enableNatpmp,
                             port_range_first: Int32(portRangeFirst),
                             port_range_second: Int32(portRangeSecond),
                             proxy_type: proxy_type_t(rawValue: UInt32(proxyType.rawValue)),
                             proxy_requires_auth: proxyRequiresAuth,
                             proxy_hostname: proxyHostname.cString(),
                             proxy_port: Int32(proxyPort),
                             proxy_username: proxyUsername.cString(),
                             proxy_password: proxyPassword.cString(),
                             proxy_peer_connections: proxyPeerConnections)
    }

    static var userPrefered: SettingsPack {
        SettingsPack(downloadLimit: UserPreferences.downloadLimit,
                     uploadLimit: UserPreferences.uploadLimit,
                     enableDht: UserPreferences.enableDht,
                     enableLsd: UserPreferences.enableLsd,
                     enableUtp: UserPreferences.enableUtp,
                     enableUpnp: UserPreferences.enableUpnp,
                     enableNatpmp: UserPreferences.enableNatpmp,
                     portRangeFirst: !UserPreferences.defaultPort ?
                         UserPreferences.portRangeFirst :
                         6881,
                     portRangeSecond: !UserPreferences.defaultPort ?
                         UserPreferences.portRangeSecond :
                         6891,
                     proxyType: UserPreferences.proxyType,
                     proxyRequiresAuth: UserPreferences.proxyRequiresAuth,
                     proxyHostname: UserPreferences.proxyHostname,
                     proxyPort: UserPreferences.proxyPort,
                     proxyUsername: UserPreferences.proxyUsername,
                     proxyPassword: UserPreferences.proxyPassword,
                     proxyPeerConnections: UserPreferences.proxyPeerConnections)
    }
}

extension SettingsPack {
    init(_ native: settings_pack_struct) {
        downloadLimit = Int(native.download_limit)
        uploadLimit = Int(native.upload_limit)
        enableDht = native.enable_dht
        enableLsd = native.enable_lsd
        enableUtp = native.enable_utp
        enableUpnp = native.enable_upnp
        enableNatpmp = native.enable_natpmp
        portRangeFirst = Int(native.port_range_first)
        portRangeSecond = Int(native.port_range_second)
        proxyType = ProxyType(rawValue: Int(native.proxy_type.rawValue))!
        proxyRequiresAuth = native.enable_natpmp
        proxyHostname = String(validatingUTF8: native.proxy_hostname) ?? ""
        proxyPort = Int(native.proxy_port)
        proxyUsername = String(validatingUTF8: native.proxy_username) ?? ""
        proxyPassword = String(validatingUTF8: native.proxy_password) ?? ""
        proxyPeerConnections = native.proxy_peer_connections
    }
}
