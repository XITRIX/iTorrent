//
//  UIRepresentable.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 17.04.2022.
//

import ReactiveKit
import UIKit

class TableCellRepresentable: Hashable, HidableItem {
    private let id = UUID()
    var action = PassthroughSubject<Void, Never>()
    var hidden: Bool { false }

    func registerCell(in tableView: UITableView) {}
    func resolveCell(in tableView: UITableView, for indexPath: IndexPath) -> UITableViewCell { UITableViewCell() }

    static func == (lhs: TableCellRepresentable, rhs: TableCellRepresentable) -> Bool {
        lhs.hidden == rhs.hidden
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
