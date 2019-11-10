//
//  StaticTableViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 10.11.2019.
//  Copyright © 2019  XITRIX. All rights reserved.
//

import UIKit

class StaticTableViewController: ThemedUIViewController, UITableViewDataSource, UITableViewDelegate {
    var tableView: ThemedUITableView!
    var data: [Section] = [] {
        didSet {
            tableView?.reloadData()
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

    init(style: UITableView.Style = .grouped) {
        super.init(nibName: nil, bundle: Bundle.main)
        setup(style: style)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func setup(style: UITableView.Style = .grouped) {
        tableView = ThemedUITableView(frame: view.frame, style: style)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(tableView)
        
        tableView.register(SegueCell.nib, forCellReuseIdentifier: SegueCell.name)
        tableView.register(SwitchCell.nib, forCellReuseIdentifier: SwitchCell.name)
        tableView.register(ButtonCell.nib, forCellReuseIdentifier: ButtonCell.name)
        tableView.register(UpdateInfoCell.nib, forCellReuseIdentifier: UpdateInfoCell.name)

        tableView.dataSource = self
        tableView.delegate = self
    }

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
