//
//  StaticHeaderFooterView.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 15.12.2022.
//  Copyright © 2022  XITRIX. All rights reserved.
//

import UIKit

class StaticHeaderFooterView: UITableViewHeaderFooterView {
    @IBOutlet private var label: UILabel!
    private let dataSource: StaticTableViewDataSource
    private let tableView: UITableView

    var text: String? {
        get { label.text }
        set {
            label.text = newValue
            textLabel?.text = newValue
        }
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

        var frame = textLabel.convert(textLabel.bounds, to: self)

        if dataSource.useInsertStyle == true {
            let res: UIEdgeInsets
            let system = tableView.parentViewController?.systemMinimumLayoutMargins
            if let system, system != .zero {
                res = UIEdgeInsets(system)
            } else {
                res = tableView.layoutMargins
            }
            frame.origin.x += res.left
        }
        label.frame = frame
    }
}
