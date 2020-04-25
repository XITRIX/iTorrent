//
//  ArrayExtentions.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 04.04.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import Foundation

extension Array where Element: Collection,
    Element.Iterator.Element: Equatable, Element.Index == Int {
    func indices(of x: Element.Iterator.Element) -> (Int, Int)? {
        for (i, row) in self.enumerated() {
            if let j = row.firstIndex(of: x) {
                return (i, j)
            }
        }
        return nil
    }
}

extension Array where Element: Hashable {
    /// Remove duplicates from the array, preserving the items order
    func filterDuplicates() -> [Element] {
        var set = Set<Element>()
        var filteredArray = [Element]()
        for item in self {
            if set.insert(item).inserted {
                filteredArray.append(item)
            }
        }
        return filteredArray
    }
}
