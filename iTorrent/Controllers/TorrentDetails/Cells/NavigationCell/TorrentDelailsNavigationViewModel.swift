//
//  TorrentDelailsNavigationViewModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 21.04.2022.
//

import UIKit
import MVVMFoundation
import Bond
import ReactiveKit

class TorrentDelailsNavigationViewModel: TableCellRepresentable {
    @Bindable var title: String

    init(title: String = "") {
        self.title = title
    }

    override func registerCell(in tableView: UITableView) {
        tableView.register(cell: TorrentDelailsNavigationCell.self)
    }

    override func resolveCell(in tableView: UITableView, for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(for: indexPath) as TorrentDelailsNavigationCell
        cell.setup(with: self)
        return cell
    }
}
