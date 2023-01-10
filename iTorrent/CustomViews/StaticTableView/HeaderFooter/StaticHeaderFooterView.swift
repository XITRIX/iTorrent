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
    private let tableView: StaticTableView
    private let label = UILabel()

    var isHeader: Bool = false {
        didSet { setNeedsLayout() }
    }

    var text: String? {
        get { label.text }
        set { label.text = newValue }
    }

    init(_ tableView: StaticTableView, _ dataSource: StaticTableViewDataSource) {
        self.tableView = tableView
        self.dataSource = dataSource
        super.init(reuseIdentifier: nil)

        textLabel?.isHidden = true

        label.numberOfLines = 0
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .footnote)
        if #available(iOS 13.0, *) {
            label.textColor = .secondaryLabel
        } else {
            label.textColor = .lightGray
        }
        addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            label.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            layoutMarginsGuide.trailingAnchor.constraint(equalTo: label.trailingAnchor),
            layoutMarginsGuide.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 8)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var defaultMargins: UIEdgeInsets {
        var res: UIEdgeInsets

        if #available(iOS 11.0, *) {
            let system = tableView.parentViewController?.systemMinimumLayoutMargins

            if let system, system != .zero {
                res = UIEdgeInsets(system)
            } else {
                res = tableView.layoutMargins
            }
        } else {
            res = .init(top: 0, left: 16, bottom: 0, right: 16)
        }

        let left = tableView.layoutSafeMargins.left
        let right = tableView.layoutSafeMargins.right

        let safeArea = tableView.safeAreaInsets

        res.left += left - safeArea.left
        res.right += right - safeArea.right

        return res
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard tableView.useInsertStyle
        else { return }

        var old = super.layoutMargins
        let def = defaultMargins

        old.left = def.left
        old.right = def.right
        old.top = isHeader ? 16 : 8

        layoutMargins = old
        label.sizeToFit()
    }
}
