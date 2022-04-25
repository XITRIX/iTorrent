//
//  TorrentDelailsSwitchViewModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 18.04.2022.
//

import UIKit
import MVVMFoundation

class TorrentDelailsSwitchViewModel: TableCellRepresentable {
    @Bindable var title: String
    @Bindable var value: Bool

    init(title: String = "", value: Bool = false) {
        self.title = title
        self.value = value
    }

    override func registerCell(in tableView: UITableView) {
        tableView.register(cell: TorrentDelailsSwitchCell.self)
    }

    override func resolveCell(in tableView: UITableView, for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(for: indexPath) as TorrentDelailsSwitchCell
        cell.setup(with: self)
        return cell
    }
}
