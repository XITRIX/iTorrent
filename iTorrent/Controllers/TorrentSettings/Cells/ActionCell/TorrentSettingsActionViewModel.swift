//
//  TorrentSettingsActionViewModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 15.05.2022.
//

import MVVMFoundation
import UIKit

class TorrentSettingsActionViewModel: TableCellRepresentable {
    @Bindable var title: String
    @Bindable var detail: String

    init(title: String = "", detail: String = "", action: @escaping ()->()) {
        self.title = title
        self.detail = detail
    }

    override func registerCell(in tableView: UITableView) {
        tableView.register(cell: TorrentSettingsActionCell.self)
    }

    override func resolveCell(in tableView: UITableView, for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(for: indexPath) as TorrentSettingsActionCell
        cell.setup(with: self)
        return cell
    }
}
