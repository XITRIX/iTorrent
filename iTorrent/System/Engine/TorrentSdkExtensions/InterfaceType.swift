//
//  InterfaceType.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 23.09.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

#if TRANSMISSION
import ITorrentTransmissionFramework
#else
import ITorrentFramework
#endif

extension InterfaceType {
    var name: String {
        switch self {
        case .all: return "InterfaceType.All".localized
        case .primary: return "InterfaceType.Primary".localized
        case .vpnOnly: return "InterfaceType.VpnOnly".localized
        case .manual(name: let name): return "\("InterfaceType.Manual".localized): \(name)"
        @unknown default: fatalError("Unknown InterfaceType member")
        }
    }
}
