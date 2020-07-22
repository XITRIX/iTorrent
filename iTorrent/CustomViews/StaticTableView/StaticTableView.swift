//
//  StaticTableView.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 19.10.2019.
//  Copyright © 2019  XITRIX. All rights reserved.
//

import UIKit

class StaticTableView: ThemedUITableView {
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
        
        register(SegueCell.nib, forCellReuseIdentifier: SegueCell.name)
        register(SwitchCell.nib, forCellReuseIdentifier: SwitchCell.name)
        register(ButtonCell.nib, forCellReuseIdentifier: ButtonCell.name)
        register(UpdateInfoCell.nib, forCellReuseIdentifier: UpdateInfoCell.name)
        register(TextFieldCell.nib, forCellReuseIdentifier: TextFieldCell.name)
        register(StoragePropertyCell.nib, forCellReuseIdentifier: StoragePropertyCell.name)

        estimatedRowHeight = 44
        rowHeight = UITableView.automaticDimension

        keyboardDismissMode = .interactive

        diffDataSource = StaticTableViewDataSource(tableView: self, cellProvider: { (tableView, indexPath, model) -> UITableViewCell in
            let cell = tableView.dequeueReusableCell(withIdentifier: model.cell.reuseCellIdentifier, for: indexPath)
            (cell as? PreferenceCellProtocol)?.setModel(model.cell)
            return cell
        })

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
}

class StaticTableViewDataSource: DiffableDataSource<Section, CellModelHolder> {
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let snapshot = snapshot else { return nil }
        return snapshot.sectionIdentifiers[section].headerFunc?() ?? Localize.get(snapshot.sectionIdentifiers[section].header)
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard let snapshot = snapshot else { return nil }
        return snapshot.sectionIdentifiers[section].footerFunc?() ?? Localize.get(snapshot.sectionIdentifiers[section].footer)
    }
}

extension StaticTableView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = presentableData[indexPath.section].rowModels[indexPath.row]
        model.cell.tapAction?()
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
