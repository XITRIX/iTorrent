//
//  PropertyStorage.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 27.04.2022.
//

import Bond
import Foundation
import ReactiveKit

class PropertyStorage {
    @StoredProperty(id: "torrentListSortingType") var torrentListSortingType = TorrentListSortingModel(type: .name)
}
