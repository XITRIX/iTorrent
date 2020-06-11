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
    func removingDuplicates() -> [Element] {
        var addedDict = [Element: Bool]()

        return filter {
            addedDict.updateValue(true, forKey: $0) == nil
        }
    }

    mutating func removeDuplicates() {
        self = self.removingDuplicates()
    }
}
