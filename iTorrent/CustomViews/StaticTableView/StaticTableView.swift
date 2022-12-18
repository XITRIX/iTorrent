//
//  StaticTableView.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 19.10.2019.
//  Copyright © 2019  XITRIX. All rights reserved.
//

import UIKit

class StaticTableView: ThemedUITableView {
    var useInsertStyle: Bool = false {
        didSet {
            diffDataSource?.useInsertStyle = useInsertStyle
        }
    }
    
    var diffDataSource: StaticTableViewDataSource!
    var data: [Section] = []
    
    var tableAnimation: UITableView.RowAnimation = .top
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

    override func setup() {
        super.setup()

        cellLayoutMarginsFollowReadableWidth = true
        register(SegueCell.nib, forCellReuseIdentifier: SegueCell.name)
        register(SwitchCell.nib, forCellReuseIdentifier: SwitchCell.name)
        register(ButtonCell.nib, forCellReuseIdentifier: ButtonCell.name)
        register(UpdateInfoCell.nib, forCellReuseIdentifier: UpdateInfoCell.name)
        register(TextFieldCell.nib, forCellReuseIdentifier: TextFieldCell.name)
        register(StoragePropertyCell.nib, forCellReuseIdentifier: StoragePropertyCell.name)
        
        addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(longPressRecogniser(_:))))

        estimatedRowHeight = 44
        rowHeight = UITableView.automaticDimension

        keyboardDismissMode = .interactive

        diffDataSource = StaticTableViewDataSource(tableView: self, cellProvider: { (tableView, indexPath, model) -> UITableViewCell in
            let cell = tableView.dequeueReusableCell(withIdentifier: model.cell.reuseCellIdentifier, for: indexPath)
            (cell as? PreferenceCellProtocol)?.setModel(model.cell)
            return cell
        })
        diffDataSource.useInsertStyle = useInsertStyle

        dataSource = diffDataSource
        delegate = self
    }

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
            self.visibleCells.forEach { cell in
                if let indexPath = self.indexPath(for: cell) {
                    (cell as? PreferenceCellProtocol)?.setModel(snapshot.getItem(from: indexPath)!.cell)
                }
            }
        }
    }
    
    @objc func longPressRecogniser(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            if let indexPath = indexPathForRow(at: gesture.location(in: self)) {
                let model = presentableData[indexPath.section].rowModels[indexPath.row]
                model.cell.longPressAction?()
            }
        }
    }
}

class StaticTableViewDataSource: DiffableDataSource<Section, CellModelHolder> {
    var useInsertStyle: Bool = false
    
    fileprivate var useInsertStyleValue: Bool {
        useInsertStyle ?? false
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let snapshot = snapshot else { return nil }
        let res = snapshot.sectionIdentifiers[section].headerFunc?() ?? Localize.get(snapshot.sectionIdentifiers[section].header)
        if res.isEmpty { return nil }
        return res.uppercased()
//        return "\(useInsertStyleValue ? "      " : "")\(res)"
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard let snapshot = snapshot else { return nil }
        let res = snapshot.sectionIdentifiers[section].footerFunc?() ?? Localize.get(snapshot.sectionIdentifiers[section].footer)
        if res.isEmpty { return nil }
        return res
//        return "\(useInsertStyleValue ? "      " : "")\(res)"
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let res = super.tableView(tableView, cellForRowAt: indexPath) as! ThemedUITableViewCell
        res.insetStyle = useInsertStyleValue
        res.setTableView(tableView)
        if useInsertStyleValue {
            res.setInsetParams(tableView: tableView, indexPath: indexPath)
        }
        return res
    }
}

extension StaticTableView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = presentableData[indexPath.section].rowModels[indexPath.row]
        model.cell.tapAction?()
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let dataSource = tableView.dataSource as? StaticTableViewDataSource,
              let res = dataSource.tableView(tableView, titleForHeaderInSection: section)
        else { return nil }

        let header = StaticHeaderFooterView(tableView as! StaticTableView, dataSource)
        header.text = res
        return header
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let dataSource = tableView.dataSource as? StaticTableViewDataSource,
              let res = dataSource.tableView(tableView, titleForFooterInSection: section)
        else { return nil }

        let header = StaticHeaderFooterView(tableView as! StaticTableView, dataSource)
        header.text = res
        return header
    }
}
