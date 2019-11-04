//
//  StaticTableView.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 19.10.2019.
//  Copyright © 2019  XITRIX. All rights reserved.
//

import UIKit

class StaticTableView: ThemedUITableView {
    var data: [Section] = [] {
        didSet {
            reloadData()
        }
    }

    private var _presentableData: [Section]?
    var presentableData: [Section] {
        get {
            if (_presentableData == nil) {
                _presentableData = [Section]()
            }
            _presentableData?.removeAll()
            data.forEach {
                _presentableData?.append(Section(rowModels: $0.rowModels.filter({ !($0.hiddenCondition?() ?? false) }),
                    header: $0.header,
                    footer: $0.footer,
                    headerFunc: $0.headerFunc,
                    footerFunc: $0.footerFunc))
            }
            return _presentableData!
        }
    }

    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func setup() {
        register(SegueCell.nib, forCellReuseIdentifier: SegueCell.name)
        register(SwitchCell.nib, forCellReuseIdentifier: SwitchCell.name)
        register(ButtonCell.nib, forCellReuseIdentifier: ButtonCell.name)
        register(UpdateInfoCell.nib, forCellReuseIdentifier: UpdateInfoCell.name)

        dataSource = self
        delegate = self
    }

    struct Section {
        var rowModels: [CellModelProtocol] = []
        var header: String = ""
        var footer: String = ""
        var headerFunc: (() -> (String))? = nil
        var footerFunc: (() -> (String))? = nil
    }
}

extension StaticTableView: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        presentableData.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        presentableData[section].rowModels.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        presentableData[section].headerFunc?() ?? Localize.get(presentableData[section].header)
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        presentableData[section].footerFunc?() ?? Localize.get(presentableData[section].footer)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = presentableData[indexPath.section].rowModels[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: model.reuseCellIdentifier, for: indexPath)
        (cell as? PreferenceCellProtocol)?.setModel(model)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = presentableData[indexPath.section].rowModels[indexPath.row]
        model.tapAction?()
    }
}
