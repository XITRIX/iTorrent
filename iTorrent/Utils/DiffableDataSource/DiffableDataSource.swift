//
//  DiffableDataSource.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 29.05.2020.
//  Copyright © 2020 XITRIX. All rights reserved.
//

import DeepDiff
import UIKit

class DiffableDataSource<SectionIdentifierType, ItemIdentifierType>: NSObject, UITableViewDataSource where SectionIdentifierType: DiffAware & Hashable, ItemIdentifierType: DiffAware & Hashable {
    public typealias CellProvider = (UITableView, IndexPath, ItemIdentifierType) -> UITableViewCell
    
    private var cellProvider: DiffableDataSource<SectionIdentifierType, ItemIdentifierType>.CellProvider?
    private weak var tableView: UITableView?
    private(set) var snapshot: DataSnapshot<SectionIdentifierType, ItemIdentifierType>?
    
    init(tableView: UITableView, cellProvider: @escaping DiffableDataSource<SectionIdentifierType, ItemIdentifierType>.CellProvider) {
        self.cellProvider = cellProvider
        self.tableView = tableView
    }
    
    let updateSemaphore = DispatchSemaphore(value: 1)
    func apply(_ snapshot: DataSnapshot<SectionIdentifierType, ItemIdentifierType>,
               animateInitial: Bool = true,
               animatingDifferences: Bool = true,
               sectionDeleteAnimation: UITableView.RowAnimation = .fade,
               sectionInsetAnimation: UITableView.RowAnimation = .fade,
               rowDeletionAnimation: UITableView.RowAnimation = .fade,
               rowInsetAnimation: UITableView.RowAnimation = .fade,
               completion: (() -> Void)? = nil) {
        if !animatingDifferences ||
            (!animateInitial && self.snapshot == nil) {
            self.snapshot = snapshot
            tableView?.reloadData()
            completion?()
            return
        }
        
        DispatchQueue.global(qos: .userInteractive).async {
            /// Lock thread to prevent collapses
            self.updateSemaphore.wait()
            
            /// Find difference between sections
            let sectionDiff = diff(old: self.snapshot?.sectionIdentifiers ?? [], new: snapshot.sectionIdentifiers)
            
            let insertsInts = sectionDiff.compactMap { $0.insert }.map { $0.index }
            let deletesInts = sectionDiff.compactMap { $0.delete }.map { $0.index }
            let moves = sectionDiff.compactMap { $0.move }.map {
                (
                    from: $0.fromIndex,
                    to: $0.toIndex
                )
            }
            
            /// Find difference between cells
            var cellChanges = [ChangeWithIndexPath]()
            for section in snapshot.sectionIdentifiers.enumerated().filter({ item in !insertsInts.contains(item.offset) && !moves.map { $0.to }.contains(item.offset) }) {
                let changes = diff(old: self.snapshot?.itemIdentifiers(inSection: section.element) ?? [], new: snapshot.itemIdentifiers(inSection: section.element))
                
                /// Deletion index must be from previous snapshot, find it, or use latest
                let deletes = changes.compactMap { $0.delete }.map { $0.index.toIndexPath(section: self.snapshot?.itemSection($0.item) ?? section.offset) }
                let inserts = changes.compactMap { $0.insert }.map { $0.index.toIndexPath(section: section.offset) }
                let replaces = changes.compactMap { $0.replace }.map { $0.index.toIndexPath(section: section.offset) }
                let moves = changes.compactMap { $0.move }.map {
                    (
                        from: $0.fromIndex.toIndexPath(section: section.offset),
                        to: $0.toIndex.toIndexPath(section: section.offset)
                    )
                }
                
                let indexes = ChangeWithIndexPath(
                    inserts: inserts,
                    deletes: deletes,
                    replaces: replaces,
                    moves: moves
                )
                
                cellChanges.append(indexes)
            }
            
            DispatchQueue.main.async {
                self.snapshot = snapshot
                
                if deletesInts.count > 0 || insertsInts.count > 0 || moves.count > 0 ||
                    cellChanges.contains(where: { $0.deletes.count > 0 || $0.inserts.count > 0 || $0.moves.count > 0 }) {
                    self.tableView?.beginUpdates()
                    if deletesInts.count > 0 { self.tableView?.deleteSections(IndexSet(deletesInts), with: sectionDeleteAnimation) }
                    if insertsInts.count > 0 { self.tableView?.insertSections(IndexSet(insertsInts), with: sectionInsetAnimation) }
                    moves.forEach { self.tableView?.moveSection($0.from, toSection: $0.to) }
                    
                    cellChanges.forEach { changes in
                        if changes.inserts.count > 0 { self.tableView?.insertRows(at: changes.inserts, with: rowInsetAnimation) }
                        if changes.deletes.count > 0 { self.tableView?.deleteRows(at: changes.deletes, with: rowDeletionAnimation) }
                        for move in changes.moves {
                            self.tableView?.moveRow(at: move.from, to: move.to)
                        }
                    }
                    self.tableView?.endUpdates()
                }
                
                self.updateSemaphore.signal()
                completion?()
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        guard cellProvider != nil,
            let snapshot = snapshot else {
            return 0
        }
        
        return snapshot.numberOfSections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        snapshot?.getItems(from: section)?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cellProvider = cellProvider else {
            fatalError("Set 'cellProvider' or override 'tableView(_,cellForRowAt) -> UITableViewCell' method")
        }
        return cellProvider(tableView, indexPath, snapshot!.getItem(from: indexPath)!)
    }
    
    open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { nil }
    
    open func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? { nil }
    
    open func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool { true }
    
    open func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {}
    
    open func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool { false }
    
    open func sectionIndexTitles(for tableView: UITableView) -> [String]? { nil }
    
    open func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard snapshot != nil else { return }
        
        snapshot!.moveItem(moveRowAt: sourceIndexPath, to: destinationIndexPath)
    }
}

struct DataSnapshot<SectionIdentifierType, ItemIdentifierType> where SectionIdentifierType: DiffAware & Hashable, ItemIdentifierType: DiffAware & Hashable {
    private var itemsDictionary: [SectionIdentifierType: [ItemIdentifierType]] = [:]
    private(set) var sectionIdentifiers: [SectionIdentifierType] = []
    private(set) var itemIdentifiers: [ItemIdentifierType] = []
    
    public var numberOfItems: Int {
        itemIdentifiers.count
    }
    
    public var numberOfSections: Int {
        if sectionIdentifiers.count == 0,
            itemIdentifiers.count > 0 {
            return 1
        }
        return sectionIdentifiers.count
    }
    
    public func getItem(from indexPath: IndexPath) -> ItemIdentifierType? {
        if sectionIdentifiers.count == 0 {
            return itemIdentifiers[indexPath.row]
        } else {
            return itemsDictionary[sectionIdentifiers[indexPath.section]]?[indexPath.row]
        }
    }
    
    public func getItems(from section: Int) -> [ItemIdentifierType]? {
        if sectionIdentifiers.count == 0,
            section == 0 {
            return itemIdentifiers
        } else if sectionIdentifiers.count > section {
            return itemsDictionary[sectionIdentifiers[section]]
        }
        return nil
    }
    
    public func itemSection(_ item: ItemIdentifierType) -> Int? {
        for section in sectionIdentifiers.enumerated() {
            if itemsDictionary[section.element]?.contains(item) ?? false {
                return section.offset
            }
        }
        return nil
    }
    
    public func numberOfItems(inSection identifier: SectionIdentifierType) -> Int {
        itemsDictionary[identifier]?.count ?? 0
    }
    
    public func itemIdentifiers(inSection identifier: SectionIdentifierType) -> [ItemIdentifierType] {
        itemsDictionary[identifier] ?? []
    }
    
    public mutating func appendSections(_ identifiers: [SectionIdentifierType]) {
        for id in identifiers {
            if itemsDictionary[id] == nil {
                itemsDictionary[id] = []
                sectionIdentifiers.append(id)
            }
        }
    }
    
    public mutating func appendItems(_ identifiers: [ItemIdentifierType], toSection sectionIdentifier: SectionIdentifierType? = nil) {
        if let sectionIdentifier = sectionIdentifier {
            itemsDictionary[sectionIdentifier]?.append(contentsOf: identifiers)
        }
        itemIdentifiers.append(contentsOf: identifiers)
    }
    
//    public mutating func removeItem() -> ItemIdentifierType {
//        NSDiffableDataSourceSnapshot
//    }

    public mutating func moveItem(moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if let item = itemsDictionary[sectionIdentifiers[sourceIndexPath.section]]?.remove(at: sourceIndexPath.row) {
            itemsDictionary[sectionIdentifiers[destinationIndexPath.section]]?.insert(item, at: destinationIndexPath.row)
        }
    }
    
    public mutating func moveItem(_ identifier: ItemIdentifierType, beforeItem toIdentifier: ItemIdentifierType) {
        moveItem(identifier, item: toIdentifier, after: false)
    }
    
    public mutating func moveItem(_ identifier: ItemIdentifierType, afterItem toIdentifier: ItemIdentifierType) {
        moveItem(identifier, item: toIdentifier, after: true)
    }
    
    private mutating func moveItem(_ identifier: ItemIdentifierType, item toIdentifier: ItemIdentifierType, after: Bool = false) {
        var indexFrom: Int?
        for section in sectionIdentifiers {
            if let index = itemsDictionary[section]?.firstIndex(of: identifier) {
                indexFrom = index
                itemsDictionary[section]?.remove(at: index)
                break
            }
        }
        
        if indexFrom == nil {
            return
        }
        
        for section in sectionIdentifiers {
            if var index = itemsDictionary[section]?.firstIndex(of: toIdentifier) {
                if after { index += 1 }
                itemsDictionary[section]?.insert(identifier, at: index)
                break
            }
        }
    }
}

fileprivate extension Int {
    func toIndexPath(section: Int) -> IndexPath {
        return IndexPath(item: self, section: section)
    }
}
