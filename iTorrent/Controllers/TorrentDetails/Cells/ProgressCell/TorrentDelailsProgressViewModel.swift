//
//  TorrentDelailsProgressViewModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 26.04.2022.
//

import UIKit
import MVVMFoundation

class TorrentDelailsProgressViewModel: TableCellRepresentable {
    @Bindable var title: String
    @Bindable var partialProgress: [Float]
    @Bindable var overallProgress: Float

    init(title: String = "", partialProgress: [Float] = [0], overallProgress: Float = 0) {
        self.title = title
        self.partialProgress = partialProgress
        self.overallProgress = overallProgress
    }

    override func registerCell(in tableView: UITableView) {
        tableView.register(cell: TorrentDelailsProgressCell.self)
    }

    override func resolveCell(in tableView: UITableView, for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(for: indexPath) as TorrentDelailsProgressCell
        cell.setup(with: self)
        return cell
    }
}
