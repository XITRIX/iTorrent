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
        if _presentableData == nil {
            _presentableData = [Section]()
        }
        _presentableData?.removeAll()
        data.forEach {
            _presentableData?.append(Section(rowModels: $0.rowModels.filter { !($0.hiddenCondition?() ?? false) },
                                             header: $0.header,
                                             footer: $0.footer,
                                             headerFunc: $0.headerFunc,
                                             footerFunc: $0.footerFunc))
        }
        return _presentableData!
    }

    override func setup() {
        super.setup()
        
        register(SegueCell.nib, forCellReuseIdentifier: SegueCell.name)
        register(SwitchCell.nib, forCellReuseIdentifier: SwitchCell.name)
        register(ButtonCell.nib, forCellReuseIdentifier: ButtonCell.name)
        register(UpdateInfoCell.nib, forCellReuseIdentifier: UpdateInfoCell.name)
        register(TextFieldCell.nib, forCellReuseIdentifier: TextFieldCell.name)
        register(StoragePropertyCell.nib, forCellReuseIdentifier: StoragePropertyCell.name)

        keyboardDismissMode = .interactive

        dataSource = self
        delegate = self
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
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
