//
//  StaticHeaderFooterView.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 15.12.2022.
//  Copyright © 2022  XITRIX. All rights reserved.
//

import UIKit

class StaticHeaderFooterView: UITableViewHeaderFooterView {
    private let dataSource: StaticTableViewDataSource
    private let tableView: UITableView

    var text: String? {
        get { textLabel?.text }
        set { textLabel?.text = newValue }
    }

    init(_ tableView: UITableView, _ dataSource: StaticTableViewDataSource) {
        self.tableView = tableView
        self.dataSource = dataSource
        super.init(reuseIdentifier: nil)

    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard let textLabel
        else { return }

        if dataSource.useInsertStyle == true {
            let res: UIEdgeInsets
            let system = tableView.parentViewController?.systemMinimumLayoutMargins
            if let system, system != .zero {
                res = UIEdgeInsets(system)
            } else {
                res = tableView.layoutMargins
            }

            let leftPoint = convert(.init(x: res.left + tableView.layoutSafeMargins.left, y: 0), to: textLabel.superview)
            textLabel.frame.origin.x = leftPoint.x
        }
    }
}
