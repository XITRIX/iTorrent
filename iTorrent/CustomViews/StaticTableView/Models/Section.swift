//
//  Section.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 10.11.2019.
//  Copyright © 2019  XITRIX. All rights reserved.
//
import DeepDiff

struct Section: Hashable, DiffAware {
    var id: Int
    var rowModels: [CellModelHolder] = []
    var header: String = ""
    var footer: String = ""
    var headerFunc: (() -> (String))?
    var footerFunc: (() -> (String))?
    
    init(rowModels: [CellModelProtocol] = [],
         header: String = "",
         footer: String = "",
         headerFunc: (() -> (String))? = nil,
         footerFunc: (() -> (String))? = nil) {
        self.rowModels = rowModels.map{CellModelHolder(cell: $0)}
        self.header = header
        self.footer = footer
        self.headerFunc = headerFunc
        self.footerFunc = footerFunc
        
        id = UUID().hashValue
        updateText()
    }
    
    mutating func updateText() {
        header = headerFunc?() ?? header
        footer = footerFunc?() ?? footer
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Section, rhs: Section) -> Bool {
        lhs.id == rhs.id
    }
    
    var diffId: Int {
        id
    }
    
    static func compareContent(_ a: Section, _ b: Section) -> Bool {
       a.id == b.id &&
        a.header == b.header &&
        a.footer == b.footer
    }
}

struct CellModelHolder: Hashable, DiffAware {
    var cell: CellModelProtocol
    var id: Int
    
    init(cell: CellModelProtocol) {
        self.cell = cell
        id = UUID().hashValue
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: CellModelHolder, rhs: CellModelHolder) -> Bool {
        if (lhs.cell as? SwitchCell.Model)?.title == "Settings.Storage.Allocate" {
            print("")
        }
        return lhs.id == rhs.id
    }
    
    var diffId: Int {
        id
    }
    
    static func compareContent(_ a: Section, _ b: Section) -> Bool {
        a == b
    }
}
