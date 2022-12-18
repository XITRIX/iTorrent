//
//  NotificationNames.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 16/08/2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let mainLoopTick = Notification.Name("mainLoopTick")
    
    static let torrentAdded = Notification.Name("torrentAdded")
    static let torrentRemoved = Notification.Name("torrentRemoved")
}
