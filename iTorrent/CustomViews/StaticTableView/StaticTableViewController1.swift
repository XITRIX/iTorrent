//
//  StaticTableViewController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 20.06.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import UIKit

class StaticTableViewController1: ThemedUITableViewController {
    var diffDataSource: StaticTableViewDataSource!
    var data: [Section] = []

    var tableAnimation: UITableView.RowAnimation { .top }
    private var _presentableData: [Section]?
    var presentableData: [Section] {
        if _presentableData == nil {
            _presentableData = [Section]()
        }
        _presentableData?.removeAll()
        data.forEach {
            var section = $0
            section.rowModels = section.rowModels.filter { !($0.cell.hiddenCondition?() ?? false) }
            if section.rowModels.count > 0 {
                section.updateText()
                _presentableData?.append(section)
            }
        }
        return _presentableData!
    }

    func setup() {
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }

        tableView.register(SegueCell.nib, forCellReuseIdentifier: SegueCell.name)
        tableView.register(SwitchCell.nib, forCellReuseIdentifier: SwitchCell.name)
        tableView.register(ButtonCell.nib, forCellReuseIdentifier: ButtonCell.name)
        tableView.register(UpdateInfoCell.nib, forCellReuseIdentifier: UpdateInfoCell.name)
        tableView.register(TextFieldCell.nib, forCellReuseIdentifier: TextFieldCell.name)
        tableView.register(StoragePropertyCell.nib, forCellReuseIdentifier: StoragePropertyCell.name)

        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableView.automaticDimension

        tableView.keyboardDismissMode = .interactive

        diffDataSource = StaticTableViewDataSource(tableView: tableView, cellProvider: { (tableView, indexPath, model) -> UITableViewCell in
            let cell = tableView.dequeueReusableCell(withIdentifier: model.cell.reuseCellIdentifier, for: indexPath)
            (cell as? PreferenceCellProtocol)?.setModel(model.cell)
            return cell
        })

        tableView.dataSource = diffDataSource
    }

    init() {
        super.init(style: .grouped)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        initSections()
        updateData()
    }

    func initSections() {}

    func updateData(animated: Bool = true) {
        var snapshot = DataSnapshot<Section, CellModelHolder>()
        let data = presentableData
        snapshot.appendSections(data)
        data.forEach { section in
            snapshot.appendItems(section.rowModels, toSection: section)
        }
        diffDataSource.apply(snapshot,
                             animateInitial: false,
                             animatingDifferences: animated,
                             sectionDeleteAnimation: tableAnimation,
                             sectionInsetAnimation: tableAnimation,
                             rowDeletionAnimation: tableAnimation,
                             rowInsetAnimation: tableAnimation) { [weak self] in
            guard let self = self else { return }
            self.tableView.visibleCells.forEach { cell in
                if let indexPath = self.tableView.indexPath(for: cell) {
                    (cell as? PreferenceCellProtocol)?.setModel(snapshot.getItem(from: indexPath)!.cell)
                }
            }
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = presentableData[indexPath.section].rowModels[indexPath.row]
        model.cell.tapAction?()
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
