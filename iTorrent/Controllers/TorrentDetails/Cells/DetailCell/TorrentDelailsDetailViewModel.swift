//
//  TorrentDelailsDetailViewModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 17.04.2022.
//

import UIKit
import MVVMFoundation

class TorrentDelailsDetailViewModel: TableCellRepresentable {
    @Bindable var title: String
    @Bindable var detail: String?

    override var hidden: Bool {
        detail.isNilOrEmpty
    }

    init(title: String = "", detail: String = "") {
        self.title = title
        self.detail = detail
    }

    override func registerCell(in tableView: UITableView) {
        tableView.register(cell: TorrentDelailsDetailCell.self)
    }

    override func resolveCell(in tableView: UITableView, for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(for: indexPath) as TorrentDelailsDetailCell
        cell.setup(with: self)
        return cell
    }
}
