//
//  SettingsPackExtension.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 01.08.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import Foundation

#if TRANSMISSION
import ITorrentTransmissionFramework
#else
import ITorrentFramework
#endif

extension SettingsPack {
    static var userPrefered: SettingsPack {
        SettingsPack(downloadLimit: UserPreferences.downloadLimit,
                     uploadLimit: UserPreferences.uploadLimit,
                     enableDht: UserPreferences.enableDht,
                     enableLsd: UserPreferences.enableLsd,
                     enableUtp: UserPreferences.enableUtp,
                     enableUpnp: UserPreferences.enableUpnp,
                     enableNatpmp: UserPreferences.enableNatpmp,
                     interfaceType: UserPreferences.interfaceType,
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
                     proxyPeerConnection: UserPreferences.proxyPeerConnections)
    }
}
