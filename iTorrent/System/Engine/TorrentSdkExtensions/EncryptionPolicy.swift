//
//  EncryptionPolicy.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 08.07.2023.
//  Copyright © 2023  XITRIX. All rights reserved.
//

#if TRANSMISSION
import ITorrentTransmissionFramework
#else
import ITorrentFramework
#endif

extension EncryptionPolicy {
    var name: String {
        switch self {
        case .enabled: return "EncryptionPolicy.Enabled".localized
        case .disabled: return "EncryptionPolicy.Disabled".localized
        case .forced: return "EncryptionPolicy.Forced".localized
        @unknown default: fatalError("Unknown EncryptionPolicy member")
        }
    }
}
