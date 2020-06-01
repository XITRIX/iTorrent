//
//  DiffCalculator.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 04.04.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import Foundation
import DeepDiff

struct SectionModel<ItemType> where ItemType: DiffAware {
    var title: String
    var items: [ItemType]
}
