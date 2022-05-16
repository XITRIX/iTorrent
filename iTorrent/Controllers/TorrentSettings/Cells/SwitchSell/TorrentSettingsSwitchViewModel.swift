//
//  TorrentSettingsSwitchViewModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 14.05.2022.
//

import MVVMFoundation
import UIKit

class TorrentSettingsSwitchViewModel: TableCellRepresentable {
    @Bindable var title: String
    @Bindable var value: Bool

    init(title: String = "", value: Bool = false) {
        self.title = title
        self.value = value
    }

    override func registerCell(in tableView: UITableView) {
        tableView.register(cell: TorrentSettingsSwitchCell.self)
    }

    override func resolveCell(in tableView: UITableView, for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(for: indexPath) as TorrentSettingsSwitchCell
        cell.setup(with: self)
        return cell
    }
}
