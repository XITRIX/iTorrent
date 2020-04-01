//
//  DiffCalculator.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 04.04.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import Foundation

struct ReloadableSection<T: Equatable>: Equatable {
    var title: String
    var value: [ReloadableCell<T>]
    var index: Int
    static func ==(lhs: ReloadableSection, rhs: ReloadableSection) -> Bool {
        return lhs.title == rhs.title && lhs.value == rhs.value
    }
}

struct ReloadableCell<T: Equatable>: Equatable {
    var key: String
    var value: T
    var index: Int
    static func ==(lhs: ReloadableCell, rhs: ReloadableCell) -> Bool {
        return lhs.value == rhs.value
    }
}

class SectionChanges {
    var insertsInts = [Int]()
    var deletesInts = [Int]()
    var updates = CellChanges()
    var moves = [(from: Int, to: Int)]()

    var inserts: IndexSet {
        return IndexSet(insertsInts)
    }

    var deletes: IndexSet {
        return IndexSet(deletesInts)
    }
    
    func hasChanges() -> Bool {
        insertsInts.count > 0 ||
        deletesInts.count > 0 ||
        moves.count > 0 ||
        updates.hasChanges()
    }
}

class CellChanges {
    var inserts = [IndexPath]()
    var deletes = [IndexPath]()
    var reloads = [IndexPath]()
    var moves = [(from: IndexPath, to: IndexPath)]()
    
    func hasChanges() -> Bool {
        inserts.count > 0 ||
        deletes.count > 0 ||
        reloads.count > 0 ||
        moves.count > 0
    }
}

struct ReloadableSectionData<N: Equatable>: Equatable {
    var items = [ReloadableSection<N>]()
    subscript(title: String) -> ReloadableSection<N>? {
        return items.first(where: {$0.title == title})
    }

    subscript(index: Int) -> ReloadableSection<N>? {
        return items.filter { $0.index == index }.first
    }
}

struct ReloadableCellData<N: Equatable>: Equatable {
    var items = [ReloadableCell<N>]()
    subscript(index: Int) -> ReloadableCell<N>? {
        return items.filter { $0.index == index }.first
    }

    subscript(key: String) -> ReloadableCell<N>? {
        return items.filter { $0.key == key }.first
    }
}

class DiffCalculator {
    static func calculate<N>(oldSectionItems: [ReloadableSection<N>], newSectionItems: [ReloadableSection<N>]) -> SectionChanges {
        let sectionChanges = SectionChanges()

        let uniqueSectionKeys = (oldSectionItems + newSectionItems)
            .map { $0.title }
            .filterDuplicates()

        let cellChanges = CellChanges()

        for sectionKey in uniqueSectionKeys {
            let oldSectionItem = ReloadableSectionData(items: oldSectionItems)[sectionKey]
            let newSectionItem = ReloadableSectionData(items: newSectionItems)[sectionKey]

            if let oldSectionItem = oldSectionItem, let newSectionItem = newSectionItem {
                // section update
                if oldSectionItem != newSectionItem {
                    let oldCellIData = oldSectionItem.value
                    let newCellData = newSectionItem.value
                    let uniqueCellKeys = (oldCellIData + newCellData)
                        .map { $0.key }
                        .filterDuplicates()

                    for cellKey in uniqueCellKeys {
                        let oldCellItem = ReloadableCellData(items: oldCellIData)[cellKey]
                        let newCellItem = ReloadableCellData(items: newCellData)[cellKey]

                        if let oldCellItem = oldCellItem, let newCellItem = newCellItem {
                            if oldCellItem != newCellItem {
                                // cell reload
                                cellChanges.reloads.append(IndexPath(row: oldCellItem.index, section: oldSectionItem.index))
                            } else if oldCellItem.index != newCellItem.index {
                                // cell move
                                cellChanges.moves.append((from: IndexPath(row: oldCellItem.index, section: oldSectionItem.index),
                                                          to: IndexPath(row: newCellItem.index, section: newSectionItem.index)))
                            }
                        } else if let oldCellItem = oldCellItem {
                            // cell delete
                            cellChanges.deletes.append(IndexPath(row: oldCellItem.index, section: oldSectionItem.index))
                        } else if let newCellItem = newCellItem {
                            // cell insert
                            cellChanges.inserts.append(IndexPath(row: newCellItem.index, section: newSectionItem.index))
                        }
                    }
                } else if oldSectionItem.index != newSectionItem.index {
                    // section move
                    sectionChanges.moves.append((from: oldSectionItem.index, to: newSectionItem.index))
                }
            } else if let oldSectionItem = oldSectionItem {
                // section delete
                sectionChanges.deletesInts.append(oldSectionItem.index)
            } else if let newSectionItem = newSectionItem {
                // section insert
                sectionChanges.insertsInts.append(newSectionItem.index)
            }
        }

        sectionChanges.updates = cellChanges
        return sectionChanges
    }
}
