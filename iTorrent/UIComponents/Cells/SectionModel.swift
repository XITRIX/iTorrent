//
//  Section.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 17.04.2022.
//

import Foundation
import MVVMFoundation

struct SectionModel<Item>: Hashable, HidableItem where Item: Hashable & HidableItem {
    @Bindable var header: String?
    @Bindable var footer: String?
    @Bindable var items: [Item] = []

    var hidden: Bool { items.allSatisfy { $0.hidden } }

    func hash(into hasher: inout Hasher) {
        hasher.combine(header)
        hasher.combine(footer)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.header == rhs.header else { return false }
        guard lhs.footer == rhs.footer else { return false }
        return true
    }
}
