//
//  UITableViewExtensions.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 28.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

extension UITableView {
    public func unifiedPerformBatchUpdates(
      _ updates: (() -> Void),
      completion: ((Bool) -> Void)?) {

      if #available(iOS 11, tvOS 11, *) {
        performBatchUpdates(updates, completion: completion)
      } else {
        beginUpdates()
        updates()
        endUpdates()
        completion?(true)
      }
    }
}
