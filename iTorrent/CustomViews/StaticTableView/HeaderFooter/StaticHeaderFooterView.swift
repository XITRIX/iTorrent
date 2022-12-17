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
            layoutMarginsGuide.bottomAnchor.constraint(equalTo: label.bottomAnchor)
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

        res.left += left
        res.right += right

        return res
    }

    override var layoutMargins: UIEdgeInsets {
        get {
            guard tableView.useInsertStyle
            else { return super.layoutMargins }

            var old = super.layoutMargins
            let def = defaultMargins

            old.left = def.left
            old.right = def.right

            return old
        }
        set { super.layoutMargins = newValue }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

//        guard let textLabel
//        else { return }
//
//        if dataSource.useInsertStyle == true {
//            let res: UIEdgeInsets
//            let system = tableView.parentViewController?.systemMinimumLayoutMargins
//            if let system, system != .zero {
//                res = UIEdgeInsets(system)
//            } else {
//                res = tableView.layoutMargins
//            }
//
//            let leftPoint = convert(.init(x: res.left + tableView.layoutSafeMargins.left, y: 0), to: textLabel.superview)
//            textLabel.frame.origin.x = leftPoint.x
//        }
    }
}

//extension StaticHeaderFooterView {
//    var tableView: UITableView? {
//        var superview = self
//        while superview != nil {
//
//        }
//    }
//}
