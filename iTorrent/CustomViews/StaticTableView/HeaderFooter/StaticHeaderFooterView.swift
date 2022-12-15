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

        guard let view = UINib(nibName: "\(Self.self)", bundle: .main).instantiate(withOwner: self).first as? UIView
        else { fatalError("\(Self.self) Xib not instantiate") }

        addSubview(view)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.frame = bounds
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
            textLabel.frame.origin.x = res.left + tableView.layoutMargins.left
        }
    }
}
