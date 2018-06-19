//
//  ManagerAddedDelegate.swift
//  iTorrent
//
//  Created by  XITRIX on 15.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import Foundation

protocol ManagerStateChangedDelegate : class {
	func managerStateChanged(manager: TorrentStatus, oldState: String, newState: String);
}
